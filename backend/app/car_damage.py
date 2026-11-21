"""CPU inference for the checked-in car damage segmentation export."""
import ast
import math

import cv2
import numpy as np
import onnxruntime as ort

SIZE = 640


class CarDamageModel:
    def __init__(self, path):
        options = ort.SessionOptions()
        options.intra_op_num_threads = 1
        options.inter_op_num_threads = 1
        options.enable_cpu_mem_arena = False
        options.enable_mem_pattern = False
        self.session = ort.InferenceSession(
            str(path), sess_options=options, providers=["CPUExecutionProvider"]
        )
        (model_input,) = self.session.get_inputs()
        if model_input.shape != [1, 3, SIZE, SIZE] or model_input.type != "tensor(float)":
            raise ValueError("Unexpected car damage input")
        self.input_name = model_input.name
        self.names = ast.literal_eval(self.session.get_modelmeta().custom_metadata_map["names"])
        if [output.shape for output in self.session.get_outputs()] != [
            [1, 4 + len(self.names) + 32, 8400], [1, 32, 160, 160]
        ]:
            raise ValueError("Unexpected car damage outputs")

    @staticmethod
    def prepare(image):
        width, height = image.size
        ratio = SIZE / max(width, height)
        resized_width = max(round(width * ratio), 1)
        resized_height = max(round(height * ratio), 1)
        left = round((SIZE - resized_width) / 2 - 0.1)
        top = round((SIZE - resized_height) / 2 - 0.1)
        resized = cv2.resize(np.asarray(image), (resized_width, resized_height))
        canvas = np.full((SIZE, SIZE, 3), 114, dtype=np.uint8)
        canvas[top:top + resized_height, left:left + resized_width] = resized
        tensor = np.ascontiguousarray(canvas.transpose(2, 0, 1)[None], dtype=np.float32)
        tensor /= 255
        return tensor, width, height, resized_width, resized_height, left, top

    def detect(self, prepared):
        tensor, width, height, resized_width, resized_height, left, top = prepared
        predictions, prototypes = self.session.run(None, {self.input_name: tensor})
        rows = predictions[0].T
        class_scores = rows[:, 4:4 + len(self.names)]
        classes = class_scores.argmax(axis=1)
        scores = class_scores.max(axis=1)
        candidates = np.flatnonzero(scores > 0.25)
        order = candidates[np.argsort(-scores[candidates], kind="stable")]
        half_size = rows[:, 2:4] / 2
        boxes = np.column_stack((rows[:, :2] - half_size, rows[:, :2] + half_size))
        offsets = classes.astype(np.float32)[:, None] * 7680
        selected = suppress(boxes + offsets, order)
        # The reference predictor drops detections with empty segmentation masks.
        prototypes = prototypes[0].reshape(32, -1)
        detections = []
        for index in selected:
            box = boxes[index]
            if not has_mask(rows[index, -32:], prototypes, box):
                continue
            normalized = box.copy()
            normalized[::2] -= left
            normalized[1::2] -= top
            normalized[::2] /= resized_width / width
            normalized[1::2] /= resized_height / height
            bounds = np.array([width, height, width, height], dtype=np.float32)
            normalized = np.clip(normalized, 0, bounds) / bounds
            detections.append({
                "label": self.names[int(classes[index])],
                "confidence": float(scores[index]),
                "bbox": normalized.tolist(),
            })
        return detections


def suppress(boxes, order):
    areas = np.prod(boxes[:, 2:] - boxes[:, :2], axis=1)
    selected = []
    while order.size and len(selected) < 300:
        index = order[0]
        selected.append(index)
        remaining = order[1:]
        corners = np.minimum(boxes[index, 2:], boxes[remaining, 2:])
        corners -= np.maximum(boxes[index, :2], boxes[remaining, :2])
        intersection = np.prod(np.maximum(corners, 0), axis=1)
        union = areas[index] + areas[remaining] - intersection
        order = remaining[intersection / union <= 0.5]
    return selected


def has_mask(coefficients, prototypes, box):
    left, top, right, bottom = [min(SIZE, max(0, math.ceil(value))) for value in box]
    if left >= right or top >= bottom:
        return False
    mask = (coefficients @ prototypes).reshape(160, 160)
    mask = cv2.resize(mask, (SIZE, SIZE))
    return bool(np.any(mask[top:bottom, left:right] > 0))
