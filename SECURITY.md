# Security policy

StillScout handles photos and video on device; cloud AI runs only when you use AI Pro or the complimentary trial, through our Supabase edge proxy.

## Reporting a vulnerability

**Please do not open a public GitHub issue for security problems.**

Email **stillscout.support@gmail.com** with:

- A clear description of the issue  
- Steps to reproduce (if applicable)  
- Impact you believe it has (data exposure, spend abuse, entitlement bypass, etc.)  

We’ll acknowledge within a few business days and work on a fix before public disclosure when possible.

## In scope

- `vision-score`, `revenuecat-webhook`, and related Supabase functions in this repo  
- Client-side secret handling and release build configuration  
- Quota / entitlement bypass that affects billing or cloud spend  

## Out of scope

- Social engineering, physical access, or third-party services we don’t control (Apple, RevenueCat, Supabase platform) except where our integration is clearly wrong  

Thank you for helping keep creators’ clips and our infrastructure safe.
