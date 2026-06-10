const sendSuccess = (res, { statusCode = 200, message = 'Success', data = null, meta } = {}) =>
  res.status(statusCode).json({
    success: true,
    message,
    data,
    meta,
  });

const sendError = (res, { statusCode = 400, message = 'Request failed', errors } = {}) =>
  res.status(statusCode).json({
    success: false,
    message,
    errors,
  });

module.exports = {
  sendSuccess,
  sendError,
};
