#!/bin/bash
 
set -e
 
# ============================================================
# UNIVERSAL HTML DEPLOY v2.0
# Git + GitHub + Tag + Release + GitHub Pages
# ============================================================
 
echo ""
echo "============================================================"
echo "        🚀 UNIVERSAL HTML DEPLOY v2.0"
echo "============================================================"
echo ""
 
# ------------------------------------------------------------
# 1. Kiểm tra Git
# ------------------------------------------------------------
 
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Không tìm thấy Git."
    exit 1
fi
 
# ------------------------------------------------------------
# 2. Kiểm tra GitHub CLI
# ------------------------------------------------------------
 
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ Chưa cài GitHub CLI (gh)."
    echo ""
    echo "Cài bằng:"
    echo "brew install gh"
    exit 1
fi
 
# ------------------------------------------------------------
# 3. Kiểm tra đăng nhập GitHub
# ------------------------------------------------------------
 
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI chưa đăng nhập."
    echo ""
    echo "Hãy chạy:"
    echo "gh auth login"
    exit 1
fi
 
# ------------------------------------------------------------
# 4. Kiểm tra index.html
# ------------------------------------------------------------
 
if [ ! -f "index.html" ]; then
    echo "❌ Không tìm thấy index.html"
    echo ""
    echo "Hãy chạy deploy.sh trong thư mục chứa index.html."
    exit 1
fi
 
# ------------------------------------------------------------
# 5. Lấy thông tin dự án
# ------------------------------------------------------------
 
GITHUB_USER="$(gh api user --jq '.login')"
REPO_NAME="$(basename "$PWD")"
 
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}"
APP_URL="https://${GITHUB_USER}.github.io/${REPO_NAME}/"
FORK_URL="${REPO_URL}/fork"
RELEASE_URL="${REPO_URL}/releases"
 
echo "👤 GitHub user : $GITHUB_USER"
echo "📦 Repository  : $REPO_NAME"
echo "📄 Entry file  : index.html"
echo ""
 
# ------------------------------------------------------------
# 6. Kiểm tra repository GitHub
# ------------------------------------------------------------
 
if ! gh repo view "${GITHUB_USER}/${REPO_NAME}" >/dev/null 2>&1; then
    echo "❌ Repository GitHub chưa tồn tại:"
    echo "   ${GITHUB_USER}/${REPO_NAME}"
    echo ""
    echo "Hãy tạo repository trên GitHub trước."
    exit 1
fi
 
echo "✅ Repository GitHub đã tồn tại."
 
# ------------------------------------------------------------
# 7. Khởi tạo Git nếu cần
# ------------------------------------------------------------
 
if [ ! -d ".git" ]; then
    echo ""
    echo "🔧 Khởi tạo Git..."
    git init
else
    echo "✅ Git repository đã tồn tại."
fi
 
# ------------------------------------------------------------
# 8. Đảm bảo branch main
# ------------------------------------------------------------
 
git branch -M main
 
echo "✅ Branch: main"
 
# ------------------------------------------------------------
# 9. Cấu hình origin
# ------------------------------------------------------------
 
if git remote get-url origin >/dev/null 2>&1; then
 
    CURRENT_REMOTE="$(git remote get-url origin)"
 
    echo ""
    echo "🔗 Remote hiện tại:"
    echo "   $CURRENT_REMOTE"
 
    if [ "$CURRENT_REMOTE" != "$REMOTE_URL" ]; then
        echo "🔧 Cập nhật origin..."
        git remote set-url origin "$REMOTE_URL"
    else
        echo "✅ Origin chính xác."
    fi
 
else
 
    echo ""
    echo "🔗 Thêm origin:"
    echo "   $REMOTE_URL"
 
    git remote add origin "$REMOTE_URL"
 
fi
 
# ------------------------------------------------------------
# 10. Lấy các tag mới nhất
# ------------------------------------------------------------
 
echo ""
echo "🏷️ Đồng bộ tags..."
 
git fetch --tags origin >/dev/null 2>&1 || true
 
# ------------------------------------------------------------
# 11. Xác định version
#
# Nếu chạy:
#
# ./deploy.sh v2.0.0
#
# → dùng v2.0.0
#
# Nếu chạy:
#
# ./deploy.sh
#
# → tự động tăng patch:
#
# v1.0.0 → v1.0.1
# ------------------------------------------------------------
 
if [ -n "$1" ]; then
 
    VERSION="$1"
 
else
 
    LATEST_TAG="$(
        git tag --list 'v[0-9]*.[0-9]*.[0-9]*' |
        sed 's/^v//' |
        sort -t. -k1,1n -k2,2n -k3,3n |
        tail -n 1
    )"
 
    if [ -z "$LATEST_TAG" ]; then
 
        VERSION="v1.0.0"
 
    else
 
        IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST_TAG"
 
        PATCH=$((PATCH + 1))
 
        VERSION="v${MAJOR}.${MINOR}.${PATCH}"
 
    fi
 
fi
 
# ------------------------------------------------------------
# 12. Kiểm tra format version
# ------------------------------------------------------------
 
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 
    echo "❌ Version không hợp lệ: $VERSION"
    echo ""
    echo "Ví dụ hợp lệ:"
    echo "   ./deploy.sh v1.0.0"
    echo "   ./deploy.sh v2.0.0"
    exit 1
 
fi
 
echo ""
echo "🏷️ Version: $VERSION"
 
# ------------------------------------------------------------
# 13. Git add
# ------------------------------------------------------------
 
echo ""
echo "📦 git add ."
 
git add .
 
# ------------------------------------------------------------
# 14. Commit
# ------------------------------------------------------------
 
if ! git diff --cached --quiet; then
 
    echo ""
    echo "📝 Tạo commit..."
 
    git commit -m "Release ${REPO_NAME} ${VERSION}"
 
else
 
    echo ""
    echo "ℹ️ Không có thay đổi mới để commit."
 
fi
 
# ------------------------------------------------------------
# 15. Push main
# ------------------------------------------------------------
 
echo ""
echo "⬆️ Push main lên GitHub..."
 
git push -u origin main
 
# ------------------------------------------------------------
# 16. Kiểm tra tag
# ------------------------------------------------------------
 
echo ""
echo "🏷️ Kiểm tra tag ${VERSION}..."
 
if git tag -l "$VERSION" | grep -q "^${VERSION}$"; then
 
    echo "ℹ️ Tag ${VERSION} đã tồn tại."
 
else
 
    git tag -a "$VERSION" -m "${REPO_NAME} ${VERSION}"
 
    echo "✅ Đã tạo tag ${VERSION}."
 
fi
 
# ------------------------------------------------------------
# 17. Push tag
# ------------------------------------------------------------
 
echo ""
echo "⬆️ Push tag ${VERSION}..."
 
git push origin "$VERSION"
 
# ------------------------------------------------------------
# 18. GitHub Release
# ------------------------------------------------------------
 
echo ""
echo "📦 Kiểm tra GitHub Release..."
 
if gh release view "$VERSION" --repo "${GITHUB_USER}/${REPO_NAME}" >/dev/null 2>&1; then
 
    echo "ℹ️ GitHub Release ${VERSION} đã tồn tại."
 
else
 
    echo "🚀 Đang tạo GitHub Release ${VERSION}..."
 
    gh release create "$VERSION" \
        --repo "${GITHUB_USER}/${REPO_NAME}" \
        --title "${REPO_NAME} ${VERSION}" \
        --generate-notes
 
    echo "✅ GitHub Release đã được tạo."
 
fi
 
# ------------------------------------------------------------
# 19. GitHub Pages
# ------------------------------------------------------------
 
echo ""
echo "🌐 Kiểm tra GitHub Pages..."
 
if gh api "repos/${GITHUB_USER}/${REPO_NAME}/pages" >/dev/null 2>&1; then
 
    echo "✅ GitHub Pages đã được bật."
 
else
 
    echo "🚀 Đang bật GitHub Pages..."
 
    gh api \
        --method POST \
        "repos/${GITHUB_USER}/${REPO_NAME}/pages" \
        -f 'source[branch]=main' \
        -f 'source[path]=/' \
        -f 'build_type=legacy'
 
    echo "✅ GitHub Pages đã được kích hoạt."
 
fi
 
# ------------------------------------------------------------
# 20. Kết quả
# ------------------------------------------------------------
 
echo ""
echo "============================================================"
echo "              🎉 DEPLOY THÀNH CÔNG"
echo "============================================================"
echo ""
 
echo "👤 OWNER:"
echo "$GITHUB_USER"
echo ""
 
echo "📦 REPOSITORY:"
echo "$REPO_URL"
echo ""
 
echo "🌐 LINK CHẠY ỨNG DỤNG:"
echo "$APP_URL"
echo ""
 
echo "🔀 LINK FORK CHO SINH VIÊN:"
echo "$FORK_URL"
echo ""
 
echo "📦 LINK RELEASE:"
echo "$RELEASE_URL"
echo ""
 
echo "🏷️ VERSION:"
echo "$VERSION"
echo ""
 
echo "============================================================"
echo "        🚀 ${REPO_NAME} ${VERSION} READY"
echo "============================================================"
echo ""
 
