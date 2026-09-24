const eslintPluginReact = require("eslint-plugin-react");

module.exports = [
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        window: "readonly",
        document: "readonly",
        // Add other globals here if needed, e.g., for Node.js or other environments
      },
    },
    plugins: {
      react: eslintPluginReact, // Register the plugin as an object
    },
    rules: {
      "no-console": "off",
      "no-unused-vars": "warn",
    },
  },
];
