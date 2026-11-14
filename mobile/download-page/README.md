# BAHAlerto download page

Open `index.html` in a browser. This standalone page needs no build or internet connection. Keep the assets and downloads folders alongside it.

The six reference screenshots guide the section order and composition: full-width white page, compact header, three-line hero and hand-held phone, four-part green strip, three benefits, dotted world map with floating picture pins, community portraits, three resource columns, two-column FAQ, and green footer.

The scroll animation is a fade-in and scale-up reveal: opacity 0 to 1, scale 0.86 to 1, and vertical translation 45px to 0. IntersectionObserver replays it at each viewport entry, with slight staggering on columns. Animations are enabled for this requested animated design; the fixed Pause animations button stops movement and shows all content immediately. Mobile resources can be swiped or moved using the arrows; desktop arrows rotate the three resources.

Downloads contain original project pictures, not an application installer. No APK was found in the mobile build folder. The phone preview is illustrative and displays no live data. Add an approved app release and its download link when available.

Assets come from the existing BAHAlerto project: mobile-logo.png, BAHAlerto Flood Alert Logo.png, admin/public/login-brand-generated.jpg, and mobile/assets (flood-alert-mascot.png, green-riverside-town-header.png, login/bahalerto-community-hero.png, home-map-preview.png, home-avatar.png, stickers/user-login-icon.png). Small interface icons and the dotted map are inline SVGs.

The generated transparent hand-held phone is saved as `assets/bahalerto-phone-hand.png`. It is illustrative, not an actual app screenshot. See `assets/phone-image-prompt.md` for the full prompt and tool provenance.

Verified in Edge at widths 360, 390, 768, 1440, and 2560: no horizontal page overflow, all pictures loaded, FAQ expands, desktop resource arrows work. With normal motion, the community scene changes from opacity 0 / scale 0.86 to opacity 1 / scale 1 after scrolling into view.

The page fills the browser width, including wide monitors. Desktop typography and illustrations scale up on large screens. Phone, map pins, portraits, clouds, and small symbols move continuously; section reveals replay after leaving and re-entering the viewport.
