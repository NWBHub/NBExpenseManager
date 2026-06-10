const express = require('express');
const { requireAuth } = require('../middleware/authMiddleware');

const buildCrudRoutes = (controller) => {
  const router = express.Router();

  router.use(requireAuth);
  router.get('/', controller.list);
  router.post('/', controller.create);
  router.get('/:id', controller.getById);
  router.patch('/:id', controller.update);
  router.delete('/:id', controller.remove);

  return router;
};

module.exports = buildCrudRoutes;
