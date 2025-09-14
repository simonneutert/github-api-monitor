# Contributing

Thanks for your interest in contributing to the GitHub API Rate Limit Monitor! 🎉

## 🤝 Be Nice

We're all here to learn and build cool stuff together. Please be respectful, helpful, and constructive in all interactions.

## 💬 Let's Discuss

Before diving into code:

1. **Have an idea?** Open an issue to discuss it first
2. **Found a bug?** Report it with details about how to reproduce it
3. **Fish shell support is now complete!** All three shells (Bash, Zsh, Fish) are fully implemented

We'll work things out together and make sure your contribution fits well with the project goals.

## 🔧 Development

The project uses a hybrid architecture with shared POSIX-compatible components:

- `shared/` - Common functionality across shells
- `*.sh` / `*.zsh` / `*.fish` - Shell-specific implementations
- Keep it simple and well-documented

## 📝 Pull Request Workflow

1. **Fork** the repository
2. **Create a branch** for your feature: `git checkout -b feature/awesome-thing`
3. **Make your changes** with clear, focused commits
4. **Test** your changes on the relevant shell(s)
5. **Submit a PR** with a clear description of what you've done

## 🧪 Testing

Since we don't have automated tests yet, please manually verify:

- Your changes work as expected
- Existing functionality isn't broken
- Output formats remain consistent
- Error handling works properly

## 🎯 What We're Looking For

- Bug fixes
- Multi-shell enhancements
- Performance improvements
- Better error messages
- Documentation improvements

## 📋 Code Style

- Follow existing patterns in the codebase
- Use clear variable names
- Add comments for complex logic
- Keep shell compatibility in mind

---

That's it! Simple as that. We believe in keeping things straightforward and focusing on building great tools together. 🚀