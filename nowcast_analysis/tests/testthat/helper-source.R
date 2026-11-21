for (path in list.files(testthat::test_path("..", "..", "R"), pattern = "\\.R$", full.names = TRUE)) {
    source(path)
}
