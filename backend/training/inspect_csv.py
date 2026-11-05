import argparse
import pandas as pd
p = argparse.ArgumentParser()
p.add_argument('csv')
a = p.parse_args()
d = pd.read_csv(a.csv)
print('ROWS:', len(d))
print('COLUMNS:', d.columns.tolist())
print(d.head(5).to_string(index=False))
print('\nMISSING VALUES:\n', d.isna().sum().to_string())
