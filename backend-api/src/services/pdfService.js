const PDFDocument = require('pdfkit');

const buildSummaryPdfBuffer = ({ userName, reportPeriod, totals, insights }) =>
  new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 48 });
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));

    doc.fontSize(22).text('Smart Expense Manager', { align: 'center' });
    doc.moveDown();
    doc.fontSize(16).text('Monthly Expense Summary');
    doc.fontSize(12).text(`User: ${userName}`);
    doc.text(`Period: ${reportPeriod}`);
    doc.moveDown();
    doc.text(`Total Expense: INR ${totals.totalExpense.toFixed(2)}`);
    doc.text(`Total Paid: INR ${totals.totalPaid.toFixed(2)}`);
    doc.text(`Total Pending: INR ${totals.totalPending.toFixed(2)}`);
    doc.moveDown();
    doc.text('Savings Recommendation');
    doc.text(insights.join('\n'));
    doc.end();
  });

module.exports = {
  buildSummaryPdfBuffer,
};
