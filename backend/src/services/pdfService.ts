import PDFDocument from 'pdfkit';

export async function generateAnalyticsReport(data: any): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', (err: Error) => reject(err));

      // Color Palette
      const primaryColor = '#2A9D8F';
      const secondaryColor = '#264653';
      const textColor = '#333333';
      const subtitleColor = '#666666';

      // Header Banner
      doc.fillColor(primaryColor).fontSize(26).text('DealSouk Analytics Report', { align: 'center' });
      doc.fillColor(subtitleColor).fontSize(11).text(`Generated on: ${new Date().toLocaleString()}`, { align: 'center' });
      doc.moveDown(1.5);

      // Divider line
      doc.strokeColor(primaryColor).lineWidth(1.5).moveTo(50, doc.y).lineTo(562, doc.y).stroke();
      doc.moveDown(1.5);

      // Platform Summary
      doc.fillColor(secondaryColor).fontSize(16).text('Platform Summary', { underline: false });
      doc.moveDown(0.5);

      const summaryY = doc.y;
      doc.fillColor(textColor).fontSize(10.5);
      
      // Column 1
      doc.text(`Submissions Today: ${data.submissionsToday}`, 50, summaryY);
      doc.text(`Submissions This Month: ${data.submissionsThisMonth}`, 50, doc.y + 5);
      doc.text(`New Users (This Month): ${data.activeUsers}`, 50, doc.y + 5);
      
      // Column 2
      doc.text(`Total Circulating Tokens: ${data.tokensNet}`, 300, summaryY);
      doc.text(`Pending Voucher Requests: ${data.pendingVouchers}`, 300, doc.y + 5);
      doc.text(`Issued Vouchers (Approved): ${data.issuedVouchers}`, 300, doc.y + 5);

      doc.moveDown(2.5);

      // Reset X offset
      doc.x = 50;

      // Trending Products
      doc.fillColor(secondaryColor).fontSize(16).text('Trending Products (This Month)');
      doc.moveDown(0.5);
      if (data.trendingProducts && data.trendingProducts.length > 0) {
        data.trendingProducts.forEach((p: any, i: number) => {
          doc.fillColor(textColor).fontSize(10.5).text(
            `${i + 1}. ${p.name} (${p.category}) — Submissions: ${p.submissions}`
          );
          doc.moveDown(0.2);
        });
      } else {
        doc.fillColor(subtitleColor).fontSize(10.5).text('No product submissions recorded this month.');
      }

      doc.moveDown(2);

      // Top Active Outlets
      doc.fillColor(secondaryColor).fontSize(16).text('Top Active Outlets (Last 7 Days)');
      doc.moveDown(0.5);
      if (data.coverageAreas && data.coverageAreas.length > 0) {
        data.coverageAreas.forEach((c: any, i: number) => {
          doc.fillColor(textColor).fontSize(10.5).text(
            `${i + 1}. ${c.chain} (${c.branchName}, ${c.area}) — Recent Submissions: ${c.recentSubmissions}`
          );
          doc.moveDown(0.2);
        });
      } else {
        doc.fillColor(subtitleColor).fontSize(10.5).text('No store submissions recorded in the last 7 days.');
      }

      // Footer
      doc.fontSize(8.5).fillColor(subtitleColor).text(
        'DealSouk Confidential. For internal administrator evaluation only.',
        50,
        720,
        { align: 'center', width: 512 }
      );

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}
