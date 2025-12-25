# 🤝 Contributing to MediLinko

Thank you for your interest in contributing to MediLinko! This guide will help you get started.

## 📖 Before You Start

1. **Read the documentation:**
   - [README.md](README.md) - Project overview
   - [QUICK_START.md](QUICK_START.md) - Get running fast
   - [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) - Firebase setup (CRITICAL)
   - [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) - Complete setup checklist

2. **Set up your development environment:**
   - Follow the [QUICK_START.md](QUICK_START.md) guide
   - Ensure all tests pass before making changes

## 🚀 Getting Started

### 1. Fork & Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/medilinko.git
cd medilinko

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/medilinko.git
```

### 2. Set Up Development Environment

**See [QUICK_START.md](QUICK_START.md) for detailed setup.**

Quick summary:
```bash
# Install dependencies
flutter pub get
cd backend && npm install

# Configure Firebase (CRITICAL)
flutterfire configure

# Set up backend .env
cp backend/.env.example backend/.env
# Edit backend/.env with your values

# Start developing!
```

### 3. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

## 📝 Development Workflow

### Code Style

**Flutter/Dart:**
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Format code with `dart format .`
- Use meaningful variable and function names
- Add comments for complex logic

**Backend/Node.js:**
- Use ESLint configuration
- Follow JavaScript Standard Style
- Use async/await for asynchronous code
- Add JSDoc comments for functions
- Use meaningful variable names

### Commit Messages

Use conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(medicine): add dosage reminder functionality"
git commit -m "fix(auth): resolve JWT token expiration issue"
git commit -m "docs: update FCM setup guide with iOS steps"
```

### Making Changes

1. **Make your changes** in your feature branch
2. **Test your changes** thoroughly
3. **Run code analysis:**
   ```bash
   # Flutter
   flutter analyze
   flutter test
   
   # Backend (if you have tests)
   cd backend
   npm test
   ```

4. **Format code:**
   ```bash
   dart format .
   ```

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: your change description"
   ```

### Testing

**Always test your changes before submitting:**

- [ ] App builds without errors
- [ ] No analyzer warnings
- [ ] Feature works as expected
- [ ] Doesn't break existing features
- [ ] Works on both Android and iOS (if applicable)
- [ ] Backend endpoints work correctly
- [ ] Database operations succeed
- [ ] Push notifications work (if modified FCM code)

## 🔄 Submitting Changes

### 1. Update Your Branch

```bash
# Fetch latest changes from upstream
git fetch upstream

# Merge upstream changes
git merge upstream/main

# Or rebase
git rebase upstream/main
```

### 2. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 3. Create Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your feature branch
4. Fill in the PR template:

```markdown
## Description
Brief description of what this PR does

## Changes
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Backend tests pass
- [ ] No analyzer warnings

## Screenshots (if UI changes)
[Add screenshots here]

## Related Issues
Closes #issue_number
```

### 4. Code Review

- Address review comments
- Make requested changes
- Push updates to the same branch
- Request re-review when ready

## 🐛 Reporting Bugs

### Before Reporting

1. **Search existing issues** to avoid duplicates
2. **Update to latest version** and check if bug persists
3. **Check documentation** for common issues

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- Device: [e.g. Pixel 6]
- OS: [e.g. Android 13]
- Flutter version: [e.g. 3.35.3]
- App version: [e.g. 1.0.0]

**Additional context**
Any other context about the problem.
```

## 💡 Feature Requests

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Any other context, mockups, or screenshots.
```

## 🔒 Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead:
- Email: [security contact email]
- Provide detailed description
- Include steps to reproduce
- Suggest a fix if possible

## 📋 Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows project style guidelines
- [ ] Ran `flutter analyze` with no errors
- [ ] Ran `dart format .`
- [ ] Added/updated tests if needed
- [ ] Updated documentation if needed
- [ ] Tested on Android and iOS (if applicable)
- [ ] No sensitive data (API keys, passwords) committed
- [ ] Commit messages follow conventional format
- [ ] PR description is clear and complete

## 🎯 Areas to Contribute

### High Priority
- [ ] Telemedicine video call integration
- [ ] Payment gateway integration
- [ ] Medicine delivery tracking
- [ ] Prescription OCR scanning

### Medium Priority
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Analytics dashboard
- [ ] Advanced search filters

### Good First Issues
- [ ] UI improvements
- [ ] Documentation updates
- [ ] Bug fixes
- [ ] Code refactoring

## 🛠️ Development Tips

### Firebase/FCM Development

When working with Firebase:
- Use your own Firebase project for testing
- Never commit `google-services.json` or `firebase-service-account.json`
- Test notifications on real devices
- Check FCM token is saved correctly

### Backend Development

- Use environment variables for all config
- Test endpoints with Postman
- Use meaningful error messages
- Validate all inputs
- Use try-catch for async operations

### Flutter Development

- Use Riverpod for state management
- Follow Material 3 design guidelines
- Make UI responsive for different screen sizes
- Test on both Android and iOS
- Use const constructors where possible

### Database Changes

- Test with both local MongoDB and Atlas
- Use proper indexing for performance
- Validate data before saving
- Handle errors gracefully
- Test edge cases

## 📚 Resources

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Documentation](https://riverpod.dev/)
- [Material 3 Guidelines](https://m3.material.io/)

### Backend
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

### Git
- [Git Documentation](https://git-scm.com/doc)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

## 🤔 Questions?

- Check the [documentation](README.md)
- Review [existing issues](https://github.com/owner/repo/issues)
- Ask in discussions/Discord/Slack

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

**Thank you for contributing to MediLinko! 🎉**

Your contributions help make healthcare more accessible and efficient.
