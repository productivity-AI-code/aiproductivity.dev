/**
 * MedRecords AI - Demo Download Lead Capture
 *
 * SETUP INSTRUCTIONS:
 * 1. Go to https://sheets.google.com and create a new spreadsheet
 * 2. Name it "MedRecords AI Leads" (or whatever you prefer)
 * 3. Add headers in Row 1: Timestamp | Name | Email | Firm | Source
 * 4. Go to Extensions > Apps Script
 * 5. Delete the default code and paste this entire file
 * 6. Click Deploy > New deployment
 * 7. Select type: "Web app"
 * 8. Set "Execute as": Me
 * 9. Set "Who has access": Anyone
 * 10. Click Deploy and authorize when prompted
 * 11. Copy the Web app URL (looks like: https://script.google.com/macros/s/XXXX/exec)
 * 12. Paste that URL into index.html where it says LEAD_WEBHOOK_URL
 *
 * OPTIONAL: Email notifications
 * - Uncomment the MailApp.sendEmail line below to get an email for each new lead
 * - Replace 'dan.direnfeld@aiproductivity.dev' with your email
 */

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);

    var name = (data.name || '').toString().substring(0, 200);
    var email = (data.email || '').toString().substring(0, 200).toLowerCase();
    var firm = (data.company || data.firm || '').toString().substring(0, 300);
    var source = (data.source || 'demo_download').toString().substring(0, 50);

    // Basic validation
    if (!email || email.indexOf('@') === -1) {
      return ContentService.createTextOutput(
        JSON.stringify({ success: false, error: 'Valid email required' })
      ).setMimeType(ContentService.MimeType.JSON);
    }

    // Write to spreadsheet
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    sheet.appendRow([
      new Date().toISOString(),
      name,
      email,
      firm,
      source
    ]);

    // Optional: Send email notification (uncomment to enable)
    // MailApp.sendEmail({
    //   to: 'dan.direnfeld@aiproductivity.dev',
    //   subject: 'New Demo Download: ' + name,
    //   body: 'Name: ' + name + '\nEmail: ' + email + '\nFirm: ' + firm + '\nTime: ' + new Date().toISOString()
    // });

    return ContentService.createTextOutput(
      JSON.stringify({ success: true })
    ).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(
      JSON.stringify({ success: false, error: err.message })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput(
    JSON.stringify({ status: 'ok', service: 'MedRecords AI Lead Capture' })
  ).setMimeType(ContentService.MimeType.JSON);
}
