# Website audit — 2026-10-14

## Inventory and baseline
Clean main at 5d902ca, tracking origin/main. No package manager, build system, tests, or Actions configuration found. 24 HTML documents: 22 indexable pages, the 404 page, and the preserved concrete-pojects redirect; two shared HTML fragments; one stylesheet; one navigation script; robots, sitemap, CNAME, redirect hints, favicon manifest and image assets. Existing Bootstrap 5.3.2 and Google Analytics are retained. Production domain is finishline-concrete.com (CNAME and existing canonical URLs agree).

## Prioritized findings (before implementation)
1. Contact has unmatched closing container/section tags. Contact is phone/email only, with no existing submission form or backend to preserve. Improve the real contact paths, SMS option, project preparation guidance, and narrow-screen email wrapping.
2. All normal pages fetch navigation/footer at runtime. This adds requests, creates layout movement, and removes essential navigation when JS or fetch fails. Inline synchronized fragments in published HTML; keep component sources and a local synchronization helper.
3. ConcreteContractor is not a Schema.org contractor subtype. Use HomeAndConstructionBusiness with one stable business identity, Service entities for actual service pages, and BreadcrumbList. Do not create local offices or addresses. Existing region-only address is insufficient for Google's address-based LocalBusiness rich result requirements; do not invent a street address.
4. FAQPage appears on contractor pages; retain useful visible FAQs but omit FAQ schema under the user's qualification rule. Google restricts FAQ rich results to authoritative government and health sites: https://developers.google.com/search/blog/2023/08/howto-faq-changes .
5. About, Contact and project galleries lack social tags. Existing canonicals and sitemap coverage are largely sound. Titles can be shortened and page-specific. 404 and typo redirect should remain noindex and outside sitemap.
6. Homepage repeats services in text-heavy sections, gives the logo more prominence than project work, and lacks contextual project links. Use real existing project photography, clear service cards, useful business strengths, process, area grid and estimate CTAs.
7. Three homepage testimonials have no provenance in repository. Withhold these from the public homepage pending verification; original text remains in Git history. Licensing/insurance claims already exist on About; retain without amplifying and request owner verification. Do not add reviews, credentials, years, or location claims.
8. Project galleries have no related service links or closing estimate CTA. Images lack intrinsic dimensions and loading hints. Actual files are often 3–7 MB. Generate resized JPEG variants from originals with Windows imaging (no dependencies), preserve originals and add responsive srcset.
9. Missing main landmarks on most pages, skipped heading levels, unlabeled mobile toggles, no shared skip link/reduced-motion/focus rules, contact overflow risk. Improve these sitewide.
10. Existing city content is mostly distinct, but several nearby-city link lists are arbitrary and repetitive. Preserve URLs and regional information; shorten link labels, style as a grid, and connect documented projects only where locations match. No new city pages.

## Scope and validation plan
Implement locally in reviewable commits: audit; shared technical SEO/accessibility; visual/content/image improvements; verification documentation. Preserve CNAME, _redirects, analytics, Bootstrap version, contact details, all public URLs and deployment settings. Validate local references/fragments, metadata uniqueness, H1 counts, heading order, JSON-LD syntax, sitemap/canonical agreement, shared fragment synchronization and image dimensions. Browser and live Google indexing checks must be reported separately from static checks. No fabricated SEO/performance scores.

## Owner review required before publication
Confirm coverage for all 12 existing cities; verify existing About licensing/insurance claims and any testimonials before reinstating them. Confirm every original project photo/location and business wording. Test phone/SMS/email on actual devices. Google Search Console and real-user Core Web Vitals need post-publication review. No publication is authorized.
