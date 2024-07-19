from tensorflow.keras.wrappers.scikit_learn import KerasClassifier
from sklearn.model_selection import RandomizedSearchCV
from keras.optimizers import Adam
from lstm_time_series_predictor import LSTMTimeSeriesPredictor

def perform_grid_search(X, Y):
    # Define a function to create the model, required for KerasRegressor
    def create_model(look_back=1, neurons=1, dropout_rate=0.0, learning_rate=0.01):
        model = LSTMTimeSeriesPredictor(
            look_back=look_back,
            neurons=neurons,
            dropout_rate=dropout_rate,
            optimizer=Adam(learning_rate=learning_rate)
        )
        return model

    # Create a KerasRegressor instance
    model = KerasRegressor(build_fn=create_model, verbose=0)

    # Define the grid search parameters
    param_dist = {
        'look_back': [1, 3, 5],
        'neurons': [50, 70, 100],
        'dropout_rate': [0.1, 0.2, 0.3],
        'learning_rate': [0.001, 0.01, 0.1],
        'batch_size': [10, 20, 40, 60, 80, 100],
        'epochs': [10, 50, 100]
    }

    # Create a RandomizedSearchCV instance
    random_search = RandomizedSearchCV(estimator=model, param_distributions=param_dist, n_iter=10, cv=3)

    # Fit the RandomizedSearchCV instance to the data
    random_search_result = random_search.fit(X, Y)

    # Return the best score and parameters
    return random_search_result.best_estimator_, random_search_result.best_score_, random_search_result.best_params_
