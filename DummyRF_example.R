# ============================================================
# 01_generate_data_and_model.R
# Simulate spatial data, fit Random Forest, and predict over grid
# ============================================================

# --- Load packages ---
packages <- c("randomForest", "raster", "sp", "terra")
lapply(packages, library, character.only = TRUE)

# --- Define project directory explicitly ---
proj_dir <- "~/SageMaker/DummyProject"
input_dir <- file.path(proj_dir, "00input")
output_dir <- file.path(proj_dir, "00output")

dir.create(input_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# --- Simulate environmental data ---
set.seed(123)
n <- 200
x <- runif(n, -10, 10)
y <- runif(n, -10, 10)
env1 <- rnorm(n, mean = 0, sd = 1)
env2 <- rnorm(n, mean = 3, sd = 1.5)
presence <- rbinom(n, 1, prob = plogis(0.3 * env1 - 0.5 * env2 + 0.1 * x))
data <- data.frame(x, y, env1, env2, presence)

# --- Save input data ---
write.csv(data, file.path(input_dir, "simulated_data.csv"), row.names = FALSE)
message("Input data saved to ", input_dir)

# --- Fit Random Forest model ---
rf_model <- randomForest(factor(presence) ~ env1 + env2 + x + y, data = data, ntree = 200)
saveRDS(rf_model, file.path(output_dir, "rf_model.rds"))
message("Random Forest model saved to ", output_dir)

# --- Generate prediction grid ---
grid_res <- 0.5
x_seq <- seq(-10, 10, by = grid_res)
y_seq <- seq(-10, 10, by = grid_res)
grid <- expand.grid(x = x_seq, y = y_seq)
grid$env1 <- rnorm(nrow(grid), mean = 0, sd = 1)
grid$env2 <- rnorm(nrow(grid), mean = 3, sd = 1.5)

# --- Predict and create raster ---
grid$pred <- predict(rf_model, newdata = grid, type = "prob")[, 2]
r <- rasterFromXYZ(grid[, c("x", "y", "pred")])
writeRaster(r, file.path(output_dir, "rf_prediction.tif"), overwrite = TRUE)
message("Prediction raster saved to ", output_dir)

# --- Plot ---
plot(r, main = "Random Forest Predictions (Dummy Data)")
points(data$x, data$y, col = ifelse(data$presence == 1, "red", "blue"), pch = 20)

cat("\nDone! All outputs stored inside DummyProject/00output.\n")
