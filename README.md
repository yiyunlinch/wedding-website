# Yiyun & Jiamin Wedding Website

Wedding website for Yiyun & Jiamin's wedding on August 15th, 2026 in Zurich, Switzerland.

Live at: [yiyunjiamin.com](https://yiyunjiamin.com)

## Architecture Overview

```
                         +---------------------------+
                         |     GitHub Pages           |
                         |  (Static Site Hosting)     |
                         +---------------------------+
                         |  index.html                |
                         |  css/ js/ images/ fonts/   |
                         +-------------+-------------+
                                       |
                            User visits website
                                       |
          +----------------------------+----------------------------+
          |                            |                            |
  1. Static Content             2. RSVP System              3. Photo Gallery
  (Bilingual UI)              (EmailJS + Google)           (AWS Serverless)
          |                            |                            |
     dom-i18n.js              EmailJS → Gmail              API Gateway
     Bulma CSS                Google Apps Script            Lambda + S3
     particles.js             Google Sheets                 Pillow + ffmpeg
```

## Project Structure

```
wedding-website/
├── index.html                          # Single-page site with all sections
├── css/
│   ├── bulma.min.css                   # Bulma CSS framework
│   ├── bulma-carousel.min.css
│   ├── styles.css                      # Custom styles (fonts, layout)
│   ├── icons.css                       # Icon animations (bounce, heartbeat, pulse)
│   └── flag-icon-css/                  # Country flag icons for language switcher
├── js/
│   ├── jquery-3.4.1.min.js
│   ├── dom-i18n.min.js                 # Internationalization (EN/CN bilingual)
│   ├── rsvp.js                         # RSVP form + EmailJS integration
│   ├── particles.min.js                # Particle animation effect
│   ├── particles-config.js
│   ├── scroll.js                       # Smooth scrolling
│   ├── bulma-carousel.min.js
│   └── fontawesome/                    # Icons
├── images/                             # Static wedding photos
├── fonts/                              # Long Cang Chinese font
├── google-apps-script.js               # Gmail → Google Sheets automation
├── emailjs-template.html               # EmailJS template (organizer notification)
├── confirmation-email-template.html    # EmailJS template (guest confirmation)
└── favicon.ico
```

## Website Sections

| # | Section | Color Theme | Description |
|---|---------|-------------|-------------|
| 1 | Hero | `is-danger` (red) | Names, background image, "tie the knot" |
| 2 | Details | `is-primary` (turquoise) | Date, time schedule, venue with Google Maps link, particle effect |
| 3 | Activities | `is-danger` (red) | Wed-Sat event schedule (city walk, hiking, BBQ, wedding day) |
| 4 | Reasons | `is-link` (blue) | 4 reasons to join, card-based layout |
| 5 | Photo Carousel | fullscreen | 7 couple photos with captions, auto-sliding carousel |
| 6 | Accommodation | `is-warning` (yellow) | 3 hotel options with maps & links |
| 7 | Travel | `is-success` (green) | Visa timeline & tips for Chinese guests |
| 8 | Invitation/RSVP | `is-info` (blue) | RSVP form with plus-one support, EmailJS integration |
| 9 | Photo Gallery | `is-dark` (dark) | Guest photo/video upload & viewing (AWS-powered) |

---

## Part 1: Bilingual Static Website

### Challenge
The wedding has both Chinese and international guests. The entire site needs to work seamlessly in both English and Chinese, including form placeholders, button labels, and content.

### Solution: dom-i18n.js with `data-translatable`

Every translatable element uses the `//` separator convention:

```html
<h1 data-translatable>
  Photo Gallery // 照片墙
</h1>
```

The `dom-i18n.js` library splits on `//` and shows the correct language. Language detection works automatically:

```javascript
// Auto-detect: English/German browsers → EN, others → CN
if (navigator.language.substring(0, 2) == 'en' || navigator.language.substring(0, 2) == 'de') {
  i18n.changeLanguage('en');
}
```

Users can also manually switch via the country flag icons (GB/CN) in the top-left navbar.

### Chinese Typography
The site uses the **Long Cang** (龙藏) handwriting font for Chinese characters, loaded from local font files to avoid dependence on Google Fonts (which is blocked in China). The font is subset-optimized to reduce file size.

### Visual Effects
- **Particle.js** animation on the date/venue section
- **CSS keyframe** animations: bouncing arrow, pulsing hearts, heartbeat on hover
- **Bulma Carousel** for the couple's photo slideshow with swipe support

---

## Part 2: RSVP System

### Challenge
Build an RSVP system that:
- Works without a traditional backend server
- Supports Chinese guests (who may not have access to Google Forms)
- Sends confirmation emails to guests
- Automatically organizes responses into a spreadsheet for wedding planning
- Handles plus-ones (up to 3 per guest)

### Architecture

```
Guest fills RSVP form on website
            |
            v
    +-------+-------+
    |   EmailJS     |  (client-side email service)
    +-------+-------+
            |
            +---> Email 1: Notification to organizers
            |     (subject: "New Wedding RSVP from {name}")
            |
            +---> Email 2: Confirmation to guest
                  (bilingual, includes RSVP summary)


Meanwhile, on Google's side:

    +-------------------+
    | Gmail Inbox       |  receives organizer notification emails
    +--------+----------+
             |
             | Google Apps Script
             | (runs every 5 minutes via time-driven trigger)
             |
             v
    +--------+----------+
    | Parse email body  |  extracts: name, email, attendance,
    | (regex matching)  |  plus-ones, notes
    +--------+----------+
             |
             v
    +--------+----------+
    | Google Sheets     |  one row per person (main contact
    | spreadsheet       |  + each plus-one as separate rows)
    +-------------------+
```

### How It Works

1. **Form Submission** (`rsvp.js`)
   - Guest fills in: name, email, attendance (yes/no), up to 3 plus-ones with notes, general wishes
   - On submit, `emailjs.send()` fires two API calls in sequence:
     - **Organizer email**: structured notification with all RSVP data
     - **Guest confirmation email**: bilingual (EN/CN based on current site language) with RSVP summary

2. **Email Templates** (hosted on EmailJS)
   - `emailjs-template.html`: organizer notification with structured data markers (`RSVP-DATA-START`/`RSVP-DATA-END`) for reliable parsing
   - `confirmation-email-template.html`: styled bilingual confirmation with conditional sections (event details shown only for "attending" guests)

3. **Gmail → Google Sheets** (`google-apps-script.js`)
   - A Google Apps Script runs every 5 minutes via a time-driven trigger
   - Searches Gmail for unread emails matching `subject:"New Wedding RSVP from"`
   - Parses email body using two strategies:
     - **Primary**: extracts structured data between `RSVP-DATA-START` / `RSVP-DATA-END` markers in the HTML body
     - **Fallback**: regex parsing of visible email content (handles edge cases)
   - Creates one row per person in Google Sheets:
     - Main contact row (with general notes)
     - Separate row for each plus-one (linked back to main contact)
   - Marks email as read after successful processing

### Why This Approach?
- **No server needed**: EmailJS handles email delivery from the browser
- **China-friendly**: the RSVP form works directly on the website (no Google Forms dependency, which is blocked in China)
- **Automatic data organization**: Google Apps Script bridges the gap between email notifications and structured spreadsheet data
- **Reliable**: dual parsing strategy (structured markers + regex fallback) ensures no RSVP is lost

---

## Part 3: Photo Gallery (AWS Serverless)

### Challenge
Build a photo/video sharing wall where wedding guests can:
- Upload photos and videos from their phones without logging in
- Browse all shared media in a responsive grid
- Download original full-resolution files
- Delete their own uploads (within a time window)

### Architecture

```
  Guest's phone/browser
            |
            |  1. POST /upload-url
            v
  +---------+---------+
  |   API Gateway     |
  |   (HTTP API)      |
  +---------+---------+
            |
            v
  +---------+---------+         +-----------------------+
  |  Lambda:          |         |  Lambda:              |
  |  wedding-gallery  | ------> |  wedding-gallery      |
  |  -api             |         |  -thumbnail           |
  +---------+---------+         +-----------+-----------+
            |                               |
  3 endpoints:                    Triggered by S3 event
  POST /upload-url                (on ObjectCreated)
  GET  /photos                              |
  DELETE /photo                   +---------+---------+
            |                     |                   |
            v                     v                   v
  +---------+---------------------+-------------------+
  |                Amazon S3 Bucket                    |
  |          yiyunjiamin-wedding-photos                |
  |                                                    |
  |   originals/              thumbnails/              |
  |   (full-size uploads)     (800px JPEG)             |
  +----------------------------------------------------+
```

### Upload Flow

```
1. Guest selects photos/videos
2. Frontend → POST /upload-url (with filename & content type)
3. Lambda generates S3 presigned URL (valid 5 min)
4. Frontend PUTs file directly to S3 via presigned URL
   (file never passes through Lambda — efficient for large files)
5. S3 event triggers thumbnail Lambda:
   - Images: Pillow resizes to 800px width JPEG
   - Videos: ffmpeg extracts first frame as JPEG thumbnail
6. Frontend polls GET /photos after 3 seconds to refresh grid
```

### Security & Access Control

| Feature | Implementation |
|---------|---------------|
| Upload authentication | Simple password gate (`yiyunjiamin2026`), stored in localStorage |
| Viewing | Public, no password needed |
| File type restriction | Frontend + backend: only image/video MIME types allowed |
| Upload expiry | Presigned URLs expire after 5 minutes |
| Self-deletion | Users can delete own uploads within 5 minutes (session-based tracking in JS memory) |
| CORS | S3 and API Gateway configured to allow requests from yiyunjiamin.com |

### Mobile Support
- `<input type="file" accept="image/*,video/*" multiple>` opens native photo picker
- Touch swipe gestures for lightbox navigation
- Responsive 2-column grid on mobile, auto-fill on desktop
- Drag & drop support on desktop

### AWS Components

| Service | Resource Name | Purpose |
|---------|--------------|---------|
| S3 | `yiyunjiamin-wedding-photos` | Store original uploads & thumbnails |
| Lambda | `wedding-gallery-api` | API: presigned URLs, list photos, delete |
| Lambda | `wedding-gallery-thumbnail` | Auto-generate thumbnails on upload |
| Lambda Layer | `pillow-layer` | Python Pillow for image resizing |
| Lambda Layer | `ffmpeg-layer` | ffmpeg binary for video frame extraction |
| API Gateway | `wedding-gallery-api` | HTTP endpoints (GET /photos, POST /upload-url, DELETE /photo) |
| IAM Role | `wedding-gallery-lambda-role` | Lambda execution permissions (S3 + CloudWatch) |

---

## Cost

The entire site runs on free or near-free infrastructure:

| Component | Cost |
|-----------|------|
| GitHub Pages hosting | Free |
| EmailJS | Free tier (200 emails/month) |
| Google Apps Script | Free |
| Google Sheets | Free |
| AWS S3 (10GB photos) | ~$0.23/month |
| AWS Lambda | Free tier (1M requests/month) |
| AWS API Gateway | Free tier (1M requests/month) |
| **Total** | **< $1/month** |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend Framework | [Bulma](https://bulma.io/) CSS |
| Language | Vanilla JavaScript (no build step) |
| Chinese Font | Long Cang (local, subset-optimized) |
| i18n | dom-i18n.js |
| Animations | CSS keyframes, particles.js |
| RSVP Emails | EmailJS (client-side) |
| RSVP Data Pipeline | Google Apps Script + Google Sheets |
| Photo Storage | AWS S3 (presigned URLs) |
| Photo API | AWS Lambda (Python 3.12) + API Gateway |
| Image Processing | Python Pillow |
| Video Processing | ffmpeg (static binary) |
| Hosting | GitHub Pages |
| DNS | Custom domain (yiyunjiamin.com) |
