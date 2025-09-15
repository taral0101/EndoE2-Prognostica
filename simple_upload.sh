#!/bin/bash

echo "🚀 Simple GitHub Upload for EndoE2-Prognostica"
echo "=============================================="

echo "First, let's verify your token works:"
echo

read -p "Enter your GitHub username: " GITHUB_USER
read -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo
echo

echo "🔍 Testing token..."
TEST_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)

if echo "$TEST_RESPONSE" | grep -q '"login"'; then
    echo "✅ Token is valid!"
    USER_LOGIN=$(echo "$TEST_RESPONSE" | grep '"login"' | sed 's/.*"login": "\([^"]*\)".*/\1/')
    echo "📝 Authenticated as: $USER_LOGIN"
else
    echo "❌ Token validation failed:"
    echo "$TEST_RESPONSE"
    echo
    echo "Please check:"
    echo "1. Token is correct and not expired"
    echo "2. Token has 'repo' scope selected"
    echo "3. You're using the token, not your password"
    exit 1
fi

echo
echo "🔧 Creating repository..."

CREATE_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -d '{
       "name":"EndoE2-Prognostica",
       "description":"Estradiol-regulated miRNA-mRNA co-expression networks as prognostic biomarkers for endometrial cancer. Validation proves clear separation is biologically authentic (HR=17.92, p<0.001).",
       "public":true
     }' \
     https://api.github.com/user/repos)

if echo "$CREATE_RESPONSE" | grep -q '"html_url"'; then
    echo "✅ Repository created successfully!"
    REPO_URL=$(echo "$CREATE_RESPONSE" | grep '"html_url"' | sed 's/.*"html_url": "\([^"]*\)".*/\1/')
    echo "📍 Repository URL: $REPO_URL"
elif echo "$CREATE_RESPONSE" | grep -q "already exists"; then
    echo "ℹ️  Repository already exists"
    REPO_URL="https://github.com/$USER_LOGIN/EndoE2-Prognostica"
else
    echo "⚠️  Repository creation had issues:"
    echo "$CREATE_RESPONSE"
    echo
    echo "Let's try to push to the repository anyway..."
    REPO_URL="https://github.com/$USER_LOGIN/EndoE2-Prognostica"
fi

echo
echo "🔧 Setting up git remote..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/$USER_LOGIN/EndoE2-Prognostica.git

echo "📤 Pushing to GitHub..."

# Create credential helper script
CRED_HELPER=$(mktemp)
cat > "$CRED_HELPER" << EOF
#!/bin/bash
echo "username=$USER_LOGIN"
echo "password=$GITHUB_TOKEN"
EOF
chmod +x "$CRED_HELPER"

# Configure git to use our credentials
git config credential.helper "!$CRED_HELPER"

if git push -u origin main; then
    echo
    echo "🎉 SUCCESS! Repository uploaded to GitHub!"
    echo "📍 View at: https://github.com/$USER_LOGIN/EndoE2-Prognostica"
    echo
    echo "✅ Your repository contains:"
    echo "   📊 3 validation heatmaps"
    echo "   📈 3 key CSV files"
    echo "   📋 README with Validation & Robustness section"
    echo "   🏥 Strong prognostic results (HR = 17.92)"
else
    echo
    echo "❌ Push failed. Let's try a different approach..."
    echo "Run these commands manually:"
    echo
    echo "git remote set-url origin https://$USER_LOGIN:$GITHUB_TOKEN@github.com/$USER_LOGIN/EndoE2-Prognostica.git"
    echo "git push -u origin main"
fi

# Clean up
rm -f "$CRED_HELPER"
git config --unset credential.helper 2>/dev/null || true