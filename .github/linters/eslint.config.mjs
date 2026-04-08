import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import nPlugin from 'eslint-plugin-n';

export default [
    {
        ignores: ['out/**', 'dist/**'],
    },
    {
        // Only .ts sources: .d.ts shims are not lint targets and avoid ESLint "ignored file" warnings in CI
        files: ['src/**/*.ts'],
        languageOptions: {
            parser: tsParser,
            parserOptions: {
                ecmaVersion: 2022,
                sourceType: 'module',
            },
        },
        plugins: {
            '@typescript-eslint': tsPlugin,
            n: nPlugin,
        },
        rules: {
            'n/no-missing-import': [
                'error',
                {
                    allowModules: [
                        'vscode',
                        '@vscode/test-electron',
                        'mocha',
                        'xpath',
                        'xmldom',
                    ],
                    tryExtensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
                },
            ],
            '@typescript-eslint/naming-convention': [
                'warn',
                {
                    selector: 'import',
                    format: ['camelCase', 'PascalCase'],
                },
            ],
            curly: 'warn',
            eqeqeq: 'warn',
            'no-throw-literal': 'warn',
            semi: ['warn', 'always'],
        },
    },
];
