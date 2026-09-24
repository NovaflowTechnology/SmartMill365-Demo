function calculateRemainingHours(plannedCompletionDate) {
  const currentDate = new Date();
  const plannedCompletion = new Date(plannedCompletionDate);
  
  const remainingTime = plannedCompletion - currentDate;
  return remainingTime > 0 ? Math.ceil(remainingTime / (1000 * 60 * 60)) : 0; // in hours
}

function calculateEstimatedCompletion(plannedCompletionDate) {
  const currentDate = new Date();
  const plannedCompletion = new Date(plannedCompletionDate);

  let estimatedCompletionDate = plannedCompletion;

  const remainingTime = plannedCompletion - currentDate;

  if (remainingTime < 0) {
    if (Math.abs(remainingTime) / (1000 * 60 * 60) > 24 * 365) { // More than a year delay
      estimatedCompletionDate = new Date(plannedCompletion);
      estimatedCompletionDate.setFullYear(estimatedCompletionDate.getFullYear() + 1); // Add 1 year
    } else if (Math.abs(remainingTime) / (1000 * 60 * 60) > 24 * 30) { // More than a month delay
      estimatedCompletionDate = new Date(plannedCompletion);
      estimatedCompletionDate.setMonth(estimatedCompletionDate.getMonth() + 1); // Add 1 month
    } else if (Math.abs(remainingTime) / (1000 * 60 * 60) > 24) { // More than 1 day delay
      estimatedCompletionDate = new Date(plannedCompletion);
      estimatedCompletionDate.setDate(estimatedCompletionDate.getDate() + 1); // Add 1 day
    }
  }

  return estimatedCompletionDate;
}

module.exports = { calculateRemainingHours, calculateEstimatedCompletion };
