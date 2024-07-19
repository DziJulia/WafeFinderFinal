from keras.callbacks import EarlyStopping
from math import sqrt
import pandas as pd
import numpy as np
from keras.models import Sequential
from keras.layers import Bidirectional, LSTM, Dense, Dropout, Input
from tensorflow.keras.losses import MeanSquaredError
from datetime import datetime
from sklearn.metrics import mean_absolute_error, mean_squared_error
import tensorflow as tf
from sklearn.model_selection import KFold

class LSTMTimeSeriesPredictor:
    """
    This class implements a Long Short-Term Memory (LSTM) model for time series prediction.
    """

    def __init__(self, optimizer, look_back=1, epochs=200, batch_size=1, dropout_rate=0.2, neurons=70):
        """
        Initializes the LSTMTimeSeriesPredictor.

        Parameters:
        look_back (int): This is the number of previous time steps to use as input features for the model.
            Increasing this value would mean that your model uses more historical data to predict the future.
            However, if this value is too high, the model might overfit to the training data and perform poorly on unseen data.
        epochs: This is the number of times the entire training dataset is shown to the model during training.
            More epochs could lead to better performance up to a point, but too many epochs can lead to overfitting.
        batch_size (int): This is the number of samples per gradient update. If you increase the batch size,
            the training process will be faster, but the model might not generalize well to unseen data.
            On the other hand, a smaller batch size might lead to a model that generalizes better, but the
            training process will be slower.
        dropout_rate (float): This is the fraction of the input units to drop to prevent overfitting. A higher dropout rate
            means more input units are dropped. It’s a regularization technique to prevent overfitting, but setting it too high might lead to underfitting.
        neurons (int): This is the number of neurons in the LSTM layers. More neurons can model more complex patterns,
            but it might also lead to overfitting if the number is too high.
        """
        self.look_back = look_back
        self.epochs = epochs
        self.optimizer = optimizer
        self.batch_size = batch_size
        self.dropout_rate = dropout_rate
        self.neurons = neurons
        self.model = Sequential()
        self.model.add(Input(shape=(1, look_back)))
        self.model.add(Bidirectional(LSTM(neurons, return_sequences=True)))
        self.model.add(Dropout(dropout_rate))
        self.model.add(Bidirectional(LSTM(neurons, return_sequences=True)))
        self.model.add(Dropout(dropout_rate))
        self.model.add(Bidirectional(LSTM(neurons)))
        self.model.add(Dropout(dropout_rate))
        self.model.add(Dense(1))
        self.model.compile(loss='mean_squared_error', optimizer='adam')

    def create_dataset(self, dataset):
        """
        Transforms the dataset into a format suitable for LSTM training.

        Parameters:
        dataset (pd.DataFrame): The original time series data.

        Returns:
        Tuple[np.array, np.array]: The transformed data (X and Y).
        """
        dataX, dataY = [], []
        for i in range(len(dataset)-self.look_back-1):
            a = dataset[i:(i+self.look_back), 0]
            dataX.append(a)
            dataY.append(dataset[i + self.look_back, 0])
        return np.array(dataX), np.array(dataY)

    @tf.function(reduce_retracing=True)
    def train_step(self, X_train, Y_train):
        with tf.GradientTape() as tape:
            predictions = self.model(X_train, training=True)
            loss_fn = MeanSquaredError()
            loss = loss_fn(Y_train, predictions)
        gradients = tape.gradient(loss, self.model.trainable_variables)
        self.model.optimizer.apply_gradients(zip(gradients, self.model.trainable_variables))
        return loss

    def fit(self, y, print_metrics=True):
        """
        Fits the model to the data.

        Parameters:
        y (np.array): The time series data.
        """
        self.y = y 
        y = np.reshape(y, (-1, 1))
        X, Y = self.create_dataset(y)
        X = np.reshape(X, (X.shape[0], 1, X.shape[1]))

        # Number of splits for K-Fold cross-validation
        n_splits = 5

        # Create a KFold object
        kf = KFold(n_splits=n_splits, shuffle=True, random_state=42)

        # Initialize results
        results = []

        # Loop over the folds
        for train_index, test_index in kf.split(X):
            # Split the data
            X_train, X_test = X[train_index], X[test_index]
            Y_train, Y_test = Y[train_index], Y[test_index]

            # Early stopping
            early_stopping = EarlyStopping(monitor='val_loss', patience=10, verbose=1, restore_best_weights=True)

            # Fit the model
            history = self.model.fit(X_train, Y_train, epochs=self.epochs, batch_size=self.batch_size, validation_data=(X_test, Y_test), callbacks=[early_stopping], verbose=0)

            # Calculate error metrics on the test set
            Y_pred = self.model.predict(X_test)
            mae = mean_absolute_error(Y_test, Y_pred)
            mse = mean_squared_error(Y_test, Y_pred)
            rmse = sqrt(mse)
            results.append((mae, mse, rmse))

        avg_mae, avg_mse, avg_rmse = np.mean(results, axis=0)

        if print_metrics:
           print(f"{datetime.now()}: Average Mean Absolute Error (MAE): {avg_mae}")
           print(f"{datetime.now()}: Average Mean Squared Error (MSE): {avg_mse}")
           print(f"{datetime.now()}: Average Root Mean Squared Error (RMSE): {avg_rmse}")

    def predict(self, steps):
        """
        Generates predictions for a specified number of future steps.

        Parameters:
        steps (int): The number of future time steps to predict.

        Returns:
        List[float]: The predicted values.
        """
        predictions = []
        for _ in range(steps):
            x = np.reshape(self.y[-self.look_back:], (1, 1, self.look_back))
            prediction = self.model.predict(x)
            self.y = np.append(self.y, prediction)
            predictions.append(prediction)
        return predictions

    def train_and_predict(self, df, target_columns, steps):
        """
        Trains the model on the data and generates predictions.

        Parameters:
        df (pd.DataFrame): The dataframe containing the time series data.
        target_columns (List[str]): The columns in the dataframe to predict.
        steps (int): The number of future time steps to predict.

        Returns:
        Dict[str, List[float]]: A dictionary mapping column names to their predicted values.
        """
        predictions = {}
        for column in target_columns:
            try:
                # Initialize a new model for each column
                model = self._initialize_model()
                predictions[column] = self._fit_and_predict(model, df[column].values.astype(float), steps)
            except Exception as exc:
                print('%r generated an exception: %s' % (column, exc))
        return predictions

    def _initialize_model(self):
        """
        Initializes a new model.

        Returns:
        keras.models.Sequential: The initialized model.
        """
        model = Sequential()
        model.add(Input(shape=(1, self.look_back)))
        model.add(Bidirectional(LSTM(self.neurons, return_sequences=True)))
        model.add(Dropout(self.dropout_rate))
        model.add(Bidirectional(LSTM(self.neurons, return_sequences=True)))
        model.add(Dropout(self.dropout_rate))
        model.add(Bidirectional(LSTM(self.neurons)))
        model.add(Dropout(self.dropout_rate))
        model.add(Dense(1))
        
        # Recreate a new optimizer instance
        optimizer = tf.keras.optimizers.Adam()
        
        model.compile(loss='mean_squared_error', optimizer=optimizer)
        return model

    def _fit_and_predict(self, model, y, steps):
        """
        Fits the model to the given data and generates predictions.

        Parameters:
        model (keras.models.Sequential): The model to fit.
        y (np.array): The time series data.
        steps (int): The number of future time steps to predict.

        Returns:
        List[float]: The predicted values.
        """
        # Reshape the data
        y = np.reshape(y, (-1, 1))
        X, Y = self.create_dataset(y)
        X = np.reshape(X, (X.shape[0], 1, X.shape[1]))

        # Number of splits for K-Fold cross-validation
        n_splits = 5
        # Create a KFold object
        kf = KFold(n_splits=n_splits, shuffle=True, random_state=42)
        # Initialize results
        results = []

        # Loop over the folds
        for train_index, test_index in kf.split(X):
            # Split the data
            X_train, X_test = X[train_index], X[test_index]
            Y_train, Y_test = Y[train_index], Y[test_index]

            # Early stopping
            early_stopping = EarlyStopping(monitor='val_loss', patience=10, verbose=1, restore_best_weights=True)
            # Fit the model
            history = model.fit(X_train, Y_train, epochs=self.epochs, batch_size=self.batch_size, validation_data=(X_test, Y_test), callbacks=[early_stopping], verbose=0)

            # Calculate error metrics on the test set
            Y_pred = model.predict(X_test)
            mae = mean_absolute_error(Y_test, Y_pred)
            mse = mean_squared_error(Y_test, Y_pred)
            rmse = sqrt(mse)

            # Store the results
            results.append((mae, mse, rmse))

        # Calculate the average results
        avg_mae, avg_mse, avg_rmse = np.mean(results, axis=0)
        print(f"{datetime.now()}: Average Mean Absolute Error (MAE): {avg_mae}")
        print(f"{datetime.now()}: Average Mean Squared Error (MSE): {avg_mse}")
        print(f"{datetime.now()}: Average Root Mean Squared Error (RMSE): {avg_rmse}")

        # Make predictions
        predictions = []
        for _ in range(steps):
            x = np.reshape(y[-self.look_back:], (1, 1, self.look_back))
            prediction = model.predict(x)
            y = np.append(y, prediction)
            predictions.append(prediction)
        return predictions
