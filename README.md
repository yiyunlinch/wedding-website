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
                    +------------------+------------------+
                    |                                     |
            Static Content                         Photo Gallery
          (served directly)                    (dynamic, via AWS)
                    |                                     |
    +---------------+---------------+                     |
    |       |       |       |       |                     |
  Hero   Schedule  Reasons  RSVP  Travel                  |
  Section Section  Section Section Section                |
    |                  |                                  |
    |            EmailJS API                              |
    |         (form submission)                           |
    |                                                     |
    +-----------------------------------------------------+
                              |
                    +---------+---------+
                    |  API Gateway      |
                    |  (HTTP API)       |
                    +---------+---------+
                              |
                 +------------+------------+
                 |                         |
        POST /upload-url            GET /photos
                 |                         |
                 v                         v
        +--------+--------+      +--------+--------+
        | Lambda:          |      | Lambda:          |
        | wedding-gallery  |      | wedding-gallery  |
        | -api             |      | -api             |
        +--------+---------+      +--------+---------+
                 |                         |
                 | Generate                | List objects
                 | presigned URL           | + presigned URLs
                 |                         |
                 v                         v
        +--------+-------------------------+--------+
        |              Amazon S3 Bucket              |
        |       yiyunjiamin-wedding-photos           |
        |                                            |
        |   originals/          thumbnails/           |
        |   (full-size          (compressed           |
        |    uploads)            800px wide)           |
        +-------------------+------------------------+
                            |
                  S3 Event Trigger
                  (on ObjectCreated)
                            |
                            v
                +-----------+-----------+
                | Lambda:               |
                | wedding-gallery       |
                | -thumbnail            |
                |                       |
                | Layers:               |
                | - Pillow (images)     |
                | - ffmpeg (videos)     |
                +-----------------------+
                            |
               +------------+------------+
               |                         |
         Image uploaded            Video uploaded
               |                         |
        Pillow resize             ffmpeg extract
        to 800px JPEG             first frame
               |                         |
               v                         v
          thumbnails/               thumbnails/
          {name}.jpg                {name}.jpg
```

## Project Structure

```
wedding-website/
├── index.html              # Single-page site with all sections
├── css/
│   ├── bulma.min.css       # Bulma CSS framework
│   ├── bulma-carousel.min.css
│   ├── styles.css          # Custom styles (fonts, layout)
│   ├── icons.css           # Icon animations (bounce, heartbeat, pulse)
│   └── flag-icon-css/      # Country flag icons for language switcher
├── js/
│   ├── jquery-3.4.1.min.js
│   ├── dom-i18n.min.js     # Internationalization (EN/CN bilingual)
│   ├── rsvp.js             # RSVP form submission via EmailJS
│   ├── particles.min.js    # Particle animation effect
│   ├── particles-config.js
│   ├── scroll.js           # Smooth scrolling
│   ├── bulma-carousel.min.js
│   └── fontawesome/        # Icons
├── images/                 # Static wedding photos
├── fonts/                  # Long Cang Chinese font
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
| 7 | Travel | `is-success` (green) | Visa timeline & tips |
| 8 | Invitation/RSVP | `is-info` (blue) | RSVP form with plus-one support, EmailJS integration |
| 9 | Photo Gallery | `is-dark` (dark) | Guest photo/video upload & viewing (AWS-powered) |

## Key Features

### Bilingual Support (EN/CN)
- Uses `dom-i18n.js` library with `data-translatable` attributes
- Auto-detects browser language (English/German → EN, others → CN)
- Language toggle via country flag icons (GB/CN) in navbar

### RSVP System
- Form collects: name, email, attendance, plus-ones (up to 3), notes
- Submitted via **EmailJS** (client-side email service, no backend needed)
- Sends confirmation email to both couple and guest

### Photo Gallery (AWS Serverless)
- **Password-protected uploads** (stored in localStorage, enter once)
- Supports images (JPG, PNG, HEIC) and videos (MP4, MOV)
- **Upload flow**: Browser → API Gateway → Lambda (presigned URL) → direct PUT to S3
- **Thumbnail generation**: S3 event triggers Lambda automatically
  - Images: resized to 800px width via Pillow
  - Videos: first frame extracted via ffmpeg
- **Viewing**: grid layout with lightbox, swipe gestures on mobile
- **Download**: original full-size file via presigned URL

## AWS Components

| Service | Resource Name | Purpose |
|---------|--------------|---------|
| S3 | `yiyunjiamin-wedding-photos` | Store original uploads & thumbnails |
| Lambda | `wedding-gallery-api` | API: generate presigned URLs & list photos |
| Lambda | `wedding-gallery-thumbnail` | Auto-generate thumbnails on upload |
| Lambda Layer | `pillow-layer` | Python Pillow for image processing |
| Lambda Layer | `ffmpeg-layer` | ffmpeg binary for video frame extraction |
| API Gateway | `wedding-gallery-api` | HTTP endpoints (GET /photos, POST /upload-url) |
| IAM Role | `wedding-gallery-lambda-role` | Lambda execution permissions (S3 + CloudWatch) |

## Cost

The AWS infrastructure is serverless and nearly free for wedding-scale usage:
- **S3 storage**: ~$0.023/GB/month (500 photos ≈ 10GB ≈ $0.23/month)
- **Lambda**: Free tier covers 1M requests/month
- **API Gateway**: Free tier covers 1M requests/month
- **Estimated total**: < $1/month

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend Framework | [Bulma](https://bulma.io/) CSS |
| Language | Vanilla JavaScript (no build step) |
| Fonts | Long Cang (Chinese handwriting) |
| i18n | dom-i18n.js |
| Animations | CSS keyframes, particles.js |
| RSVP Backend | EmailJS (client-side) |
| Photo Storage | AWS S3 |
| Photo API | AWS Lambda + API Gateway |
| Image Processing | Python Pillow |
| Video Processing | ffmpeg |
| Hosting | GitHub Pages |
| DNS | Custom domain (yiyunjiamin.com) |
