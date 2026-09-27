from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import RandomForestRegressor


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
MODEL_DIR = BASE_DIR / "models"


def train_model(csv_name: str, target_column: str, model_name: str) -> None:
    csv_path = DATA_DIR / csv_name

    if not csv_path.exists():
        raise FileNotFoundError(f"Dataset not found: {csv_path}")

    df = pd.read_csv(csv_path)
    df.columns = df.columns.str.strip()

    if target_column not in df.columns:
        raise ValueError(
            f"Can't find target column '{target_column}' in {csv_name}. "
            f"Columns found: {list(df.columns)}"
        )

    # Ignore index/date columns that should not be used for prediction.
    df = df.drop(
        columns=[column for column in ["Unnamed: 0", "Date"] if column in df.columns],
        errors="ignore",
    )

    # Convert the target price to numbers and remove rows without a valid price.
    df[target_column] = pd.to_numeric(
        df[target_column].astype(str).str.replace(r"[^\d.]", "", regex=True),
        errors="coerce",
    )
    df = df.dropna(subset=[target_column])

    if len(df) < 10:
        raise ValueError(f"Not enough valid rows to train {model_name}: {len(df)}")

    X = df.drop(columns=[target_column])
    y = df[target_column]

    numeric_columns = X.select_dtypes(include=["number"]).columns.tolist()
    categorical_columns = X.select_dtypes(exclude=["number"]).columns.tolist()

    numeric_pipeline = Pipeline(
        steps=[("imputer", SimpleImputer(strategy="median"))]
    )
    categorical_pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]
    )

    preprocessing = ColumnTransformer(
        transformers=[
            ("numeric", numeric_pipeline, numeric_columns),
            ("categorical", categorical_pipeline, categorical_columns),
        ]
    )

    model = Pipeline(
        steps=[
            ("preprocessing", preprocessing),
            (
                "regressor",
                RandomForestRegressor(
                    n_estimators=200,
                    random_state=42,
                    n_jobs=-1,
                ),
            ),
        ]
    )

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model.fit(X_train, y_train)
    predictions = model.predict(X_test)

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_path = MODEL_DIR / model_name
    joblib.dump(model, model_path)

    print(f"\n{csv_name}")
    print(f"Rows used: {len(df)}")
    print(f"MAE: {mean_absolute_error(y_test, predictions):,.2f}")
    print(f"R² score: {r2_score(y_test, predictions):.3f}")
    print(f"Saved model: {model_path}")


if __name__ == "__main__":
    train_model(
        csv_name="car_price_dataset.csv",
        target_column="Price",
        model_name="car_price_model.joblib",
    )

    train_model(
        csv_name="BIKE DETAILS.csv",
        target_column="selling_price",
        model_name="bike_price_model.joblib",
    )