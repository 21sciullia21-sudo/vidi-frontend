# Freelance Marketplace for Video Editors & VFX Artists

## Overview
A modern social marketplace platform where clients post video editing jobs, freelance editors bid on projects, and creators share work in a community feed. Users can also sell VFX packs and assets.

## Core Features

### 1. User Management
- Dual role system: Client and Freelancer (switchable)
- Profile with bio, skill level, hourly rate, location
- Portfolio grid display
- Followers/Following system
- Specializations tags
- "New" badge for recent users

### 2. Job Marketplace
- Clients post jobs with budget range and deadline
- Freelancers browse and filter jobs
- Category-based organization
- Search functionality
- Private bidding system:
  - Editors submit bid amount (private)
  - Delivery time estimate
  - Proposal/pitch
  - Only client sees bid amounts
  - Other users see number of bids
- Filter and sort bids (client view)

### 3. Social Feed
- Create posts with text and images
- Like and comment system
- Community engagement
- Share portfolio work
- Real-time feed updates

### 4. Asset Store
- Sell VFX packs, presets, templates
- Product listings with images and descriptions
- Purchase system
- Email delivery of digital assets
- Seller storefront on profile

### 5. Profiles
- View mode: Stats, bio, portfolio grid, assets
- Edit mode: Update information, manage portfolio
- Show posts on profile toggle
- Portfolio items display
- Asset storefront section

## Data Models

### User
- id, name, email, password
- profilePicUrl, bio
- skillLevel (Beginner/Intermediate/Expert)
- hourlyRate, location
- currentRole (client/freelancer)
- followers, following, projectCount
- specializations[]
- isNew, createdAt, updatedAt

### Job
- id, title, description
- category, budgetMin, budgetMax
- deadline, clientId
- status (open/in-progress/completed)
- requirements, postedAt

### Bid
- id, jobId, editorId
- amount (private), deliveryDays
- proposal, submittedAt
- status (pending/accepted/rejected)

### Post
- id, userId, content
- imageUrls[], likes[], commentCount
- createdAt, updatedAt

### Comment
- id, postId, userId
- content, createdAt

### Asset
- id, sellerId, title, description
- price, category, imageUrl
- downloadUrl, createdAt

### Purchase
- id, assetId, buyerId
- customerEmail, purchaseDate
- deliveryStatus

## Navigation Structure

### Main Bottom Navigation
1. **Feed** - Community posts
2. **Jobs** - Browse and bid on projects
3. **Store** - Browse VFX packs/assets
4. **Profile** - User profile and settings

### Additional Screens
- Job Detail & Submit Bid
- Profile Edit
- Create Post
- Asset Detail & Purchase
- Other User Profile View
- My Bids (freelancer view)
- My Jobs (client view)
- Role Switcher

## Technical Architecture

### Services Layer
- UserService: Authentication, profile management, role switching
- JobService: CRUD operations, filtering, search
- BidService: Submit, manage, filter bids
- PostService: Create, like, comment
- AssetService: List, purchase, email delivery
- All using local storage (shared_preferences)

### State Management
- Provider pattern for app state
- Separate providers for user, jobs, feed, store

### Design System
- Dark theme with sleek black backgrounds
- Accent colors: Purple/blue for badges, white for CTAs
- Card-based layouts with rounded corners
- Minimalist icons and clean typography
- Smooth animations and transitions

## Storage Strategy
- Local storage with shared_preferences
- Sample data for demonstration
- Structured JSON for complex objects
- Image URLs for assets (placeholder images)
