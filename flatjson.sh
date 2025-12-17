#!/bin/bash
echo "Updating ALL translation keys to flat structure..."

# ===== COMMON NAVIGATION =====
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.home/common.navHome/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.work/common.navWork/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.about/common.navAbout/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.stories/common.navStories/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.collection/common.navCollection/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.contact/common.navContact/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.subscribe/common.navSubscribe/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.nav\.tools/common.navTools/g' {} \;

# ===== COMMON LANGUAGES =====
find ./src -name "*.svelte" -exec sed -i 's/common\.lang\.es/common.langEs/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.lang\.en/common.langEn/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/common\.lang\.fr/common.langFr/g' {} \;

# ===== HOME PAGE =====
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.meta\.title/pages.home.metaTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.meta\.description/pages.home.metaDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.hero\.title/pages.home.heroTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.hero\.subtitle/pages.home.heroSubtitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.about\.title/pages.home.aboutTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.about\.p1/pages.home.aboutP1/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.about\.p2/pages.home.aboutP2/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.signup\.title/pages.home.signupTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.home\.signup\.description/pages.home.signupDescription/g' {} \;

# ===== TOOLS PAGE =====
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.meta\.title/pages.tools.metaTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.meta\.description/pages.tools.metaDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.status\.available/pages.tools.statusAvailable/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.status\.comingSoon/pages.tools.statusComingSoon/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.status\.future/pages.tools.statusFuture/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.palettes\.title/pages.tools.palettesTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.palettes\.description/pages.tools.palettesDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.wallpapers\.title/pages.tools.wallpapersTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.wallpapers\.description/pages.tools.wallpapersDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.avatarCreator\.title/pages.tools.avatarCreatorTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.avatarCreator\.description/pages.tools.avatarCreatorDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.stickers\.title/pages.tools.stickersTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.stickers\.description/pages.tools.stickersDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.arTryOn\.title/pages.tools.arTryOnTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.arTryOn\.description/pages.tools.arTryOnDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.nfts\.title/pages.tools.nftsTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.nfts\.description/pages.tools.nftsDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.cta\.title/pages.tools.ctaTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.cta\.description/pages.tools.ctaDescription/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.tools\.cta\.button/pages.tools.ctaButton/g' {} \;

# ===== COLLECTION PAGE =====
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.stats\.viewed/pages.collection.statsViewed/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.stats\.totalViews/pages.collection.statsTotalViews/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.stats\.favorites/pages.collection.statsFavorites/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.stats\.toDiscover/pages.collection.statsToDiscover/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.filters\.all/pages.collection.filtersAll/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.filters\.visited/pages.collection.filtersVisited/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.filters\.favorites/pages.collection.filtersFavorites/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.filters\.unvisited/pages.collection.filtersUnvisited/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.sort\.label/pages.collection.sortLabel/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.sort\.recent/pages.collection.sortRecent/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.sort\.frequent/pages.collection.sortFrequent/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.sort\.alphabetical/pages.collection.sortAlphabetical/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.actions\.export/pages.collection.actionsExport/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.actions\.clear/pages.collection.actionsClear/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.actions\.confirmClear/pages.collection.actionsConfirmClear/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.view/pages.collection.cardView/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.lastViewed/pages.collection.cardLastViewed/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.addFavorite/pages.collection.cardAddFavorite/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.removeFavorite/pages.collection.cardRemoveFavorite/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.shareWhatsApp/pages.collection.cardShareWhatsApp/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.card\.copyLink/pages.collection.cardCopyLink/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.share\.checkOut/pages.collection.shareCheckOut/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.toast\.added/pages.collection.toastAdded/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.toast\.removed/pages.collection.toastRemoved/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.toast\.linkCopied/pages.collection.toastLinkCopied/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.toast\.cleared/pages.collection.toastCleared/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.empty\.title/pages.collection.emptyTitle/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.empty\.message/pages.collection.emptyMessage/g' {} \;
find ./src -name "*.svelte" -exec sed -i 's/pages\.collection\.empty\.cta/pages.collection.emptyCta/g' {} \;

echo "COMPLETE: All translation keys updated to flat structure!"
