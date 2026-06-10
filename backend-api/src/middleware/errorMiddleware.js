const { sendError } = require('../utils/responseHandler');

const notFoundHandler = (req, res) => {
  sendError(res, {
    statusCode: 404,
    message: `Route not found: ${req.method} ${req.originalUrl}`,
  });
};

const errorHandler = (error, req, res, next) => {
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal server error';

  if (res.headersSent) {
    return next(error);
  }

  return sendError(res, {
    statusCode,
    message,
    errors: error.errors,
  });
};

module.exports = {
  notFoundHandler,
  errorHandler,
};
