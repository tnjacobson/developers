#-------------------------------------------------------------------------------
#Function to Check Coverage Rates
#-------------------------------------------------------------------------------
check_coverage <- function(data) {
  # Initialize an empty data frame to store coverage information
  coverage_df <- data.frame(
    Variable = character(0),
    Coverage = numeric(0)
  )
  
  # Loop through each variable in the data frame
  for (col_name in colnames(data)) {
    # Calculate coverage for the current variable
    coverage <- mean(!is.na(data[[col_name]])) * 100
    
    # Create a row for the coverage information
    row <- data.frame(
      Variable = col_name,
      Coverage = coverage
    )
    
    # Append the row to the coverage data frame
    coverage_df <- rbind(coverage_df, row)
  }
  
  # Return the coverage data frame
  return(coverage_df)
}