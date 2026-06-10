const Notification = require('../models/Notification');

const createNotification = async ({ userId, title, body, type, scheduledFor, metadata }) =>
  Notification.create({
    userId,
    title,
    body,
    type,
    scheduledFor,
    metadata,
  });

module.exports = {
  createNotification,
};
