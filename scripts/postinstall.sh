test -d .git && mkdir -p git-hooks && cp git-hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
exit 0