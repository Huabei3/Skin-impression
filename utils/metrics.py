import numpy as np
from scipy.stats import pearsonr, spearmanr
from sklearn.metrics import mean_absolute_error, mean_squared_error


def calculate_metrics(y_true, y_pred):
    """
    Calculate evaluation metrics for regression tasks
    
    Args:
        y_true: Ground truth values, shape (N,) or (N, 1)
        y_pred: Predicted values, shape (N,) or (N, 1)
    
    Returns:
        dict: Dictionary containing PC, SRCC, MAE, RMSE
    """
    # Flatten arrays
    y_true = y_true.flatten()
    y_pred = y_pred.flatten()
    
    # Pearson Correlation Coefficient
    pc, _ = pearsonr(y_true, y_pred)
    
    # Spearman Rank Correlation Coefficient
    srcc, _ = spearmanr(y_true, y_pred)
    
    # Mean Absolute Error
    mae = mean_absolute_error(y_true, y_pred)
    
    # Root Mean Squared Error
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    
    return {
        'PC': pc,
        'SRCC': srcc,
        'MAE': mae,
        'RMSE': rmse
    }


if __name__ == '__main__':
    # Test metrics
    y_true = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
    y_pred = np.array([1.1, 2.2, 2.9, 4.1, 4.8])
    
    metrics = calculate_metrics(y_true, y_pred)
    
    print("Test Metrics:")
    for key, value in metrics.items():
        print(f"{key}: {value:.4f}")
