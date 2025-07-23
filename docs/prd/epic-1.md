# Epic 1: User Authentication & Profile

## Overview
Implement core user authentication and profile management functionality for the Up2 iOS app.

## Description
- Sign up / login with phone or email
- Create a personal profile with avatar, vibe tags, event history

## Stories

### Story 1.1: User Registration System
**As a** new user,
**I want** to sign up using my phone number or email address,
**so that** I can create an account and access the Up2 app.

**Acceptance Criteria:**
1. User can register with phone number OR email address
2. Registration form validates input (valid phone/email format)
3. User receives verification code via SMS or email
4. User can enter verification code to complete registration
5. System creates user account upon successful verification
6. User is redirected to profile setup after registration
7. Error handling for invalid inputs and verification failures

### Story 1.2: User Authentication (Login)
**As a** returning user,
**I want** to log in using my phone number or email,
**so that** I can access my existing account and app features.

**Acceptance Criteria:**
1. User can log in with registered phone number OR email
2. System validates credentials against stored user data
3. User receives verification code for secure login
4. User can enter verification code to complete login
5. System grants access to authenticated user
6. User is redirected to main app after successful login
7. Error handling for invalid credentials and failed verification

### Story 1.3: Personal Profile Creation
**As a** authenticated user,
**I want** to create and customize my personal profile,
**so that** I can express my personality and connect with others.

**Acceptance Criteria:**
1. User can upload and set profile avatar/photo
2. User can add personal vibe tags from predefined list
3. User can view their event attendance history
4. Profile displays user's basic information (name, avatar, vibe tags)
5. User can edit and update profile information
6. Profile data is saved and persists across app sessions
7. Profile is visible to other users in appropriate contexts 