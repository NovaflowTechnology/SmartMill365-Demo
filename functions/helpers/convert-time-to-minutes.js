const convertTimeToMinutes = (timeString) => {
  if (!timeString || timeString === '00:00:00') {
    return 0;
  }
  
  const [hours, minutes, seconds] = timeString.split(':').map(Number);
  return hours * 60 + minutes + (seconds / 60);
};

module.exports = { convertTimeToMinutes };