import numpy as np
from statsmodels.tsa.statespace.sarimax import SARIMAX
from concurrent.futures import ThreadPoolExecutor, as_completed
import logging
from sklearn.model_selection import ParameterGrid

class TimeSeriesPredictor:
    """
    A class used to predict time series data using SARIMAX model.

    @param order: The (p,d,q) order of the model for the number of AR parameters,
        differences, and MA parameters to use.
    @param seasonal_order: The (P,D,Q,s) order of the seasonal component of the model for the AR parameters,
        differences, MA parameters, and periodicity.
    """
    logging.basicConfig(level=logging.INFO,
                        format='%(threadName)s: %(message)s')
    
    def __init__(self, order=(1, 1, 1), seasonal_order=(0, 0, 0, 0)):
        self.order = order
        self.seasonal_order = seasonal_order
        self.model = None
        self.y = None

    def fit(self, y):
        """
        Fit the SARIMAX model to the time series data.

        @param y: The time series data.
        """
        self.y = y
        self.model = SARIMAX(self.y, order=self.order, seasonal_order=self.seasonal_order)
        self.model_fit = self.model.fit()

    def predict(self, steps):
        """
        Predict the future values of the time series data.

        @param steps: The number of future steps to predict.

        @return: The predicted values of the time series data.
        """
        return self.model_fit.predict(start=len(self.y), end=len(self.y)+steps-1)

    def _fit_and_predict(self, y, steps):
        """
        Fit the SARIMAX model to the time series data and predict the future values.

        @param y: The time series data.
        @param steps: The number of future steps to predict.

        @return: The predicted values of the time series data.
        """
        logging.info('Running')
        self.fit(y)
        return self.predict(steps)
    
    def train_and_predict(self, df, target_columns, steps):
        """
        Train the SARIMAX model on multiple time series data and predict the future values.

        @param df: The DataFrame containing the time series data.
        @param target_columns: The columns in the DataFrame to predict.
        @param steps: The number of future steps to predict.

        @return: A dictionary where the keys are the target_columns and the values are the predicted values.
        """
        predictions = {}
        with ThreadPoolExecutor() as executor:
            future_to_column = {executor.submit(self._fit_and_predict, df[column].values.astype(float), steps): column for column in target_columns}
            for future in as_completed(future_to_column):
                column = future_to_column[future]
                try:
                    predictions[column] = future.result()
                except Exception as exc:
                    print('%r generated an exception: %s' % (column, exc))
        return predictions

    def grid_search(self, df, target_columns, param_grid):
        """
        Perform a grid search to find the best parameters for the SARIMAX model.

        @param df: The DataFrame containing the time series data.
        @param target_columns: The columns in the DataFrame to predict.
        @param param_grid: The grid of parameters to search over.

        @return: The best parameters for the SARIMAX model.
        """
        grid = ParameterGrid(param_grid)
        best_score = float('inf')
        best_params = None
        for params in grid:
            self.order = params['order']
            self.seasonal_order = params['seasonal_order']
            try:
                self.fit(df[target_columns].values.astype(float))
                mse = ((self.y - self.model_fit.fittedvalues) ** 2).mean()
                if mse < best_score:
                    best_score = mse
                    best_params = params
            except:
                continue
        return best_params
