#!/usr/bin/env node
/**
 * Safe launcher for the experimental WhatsApp/Baileys bridge.
 *
 * The Baileys bridge is intentionally disabled by default in the IoT fork:
 * npm audit currently reports GHSA-qvv5-jq5g-4cgg against the Baileys RC line
 * used by this bridge, with no fixed version available. Keeping Baileys out of
 * package.json prevents default installs and GitHub dependency alerts from
 * pulling a known-critical optional integration into Pi2/minimal deployments.
 *
 * To opt in on a reviewed, isolated host:
 *   cd scripts/whatsapp-bridge
 *   npm run install:unsafe-baileys
 *   HERMES_ENABLE_EXPERIMENTAL_WHATSAPP_BRIDGE=1 npm start
 */

const truthy = new Set(['1', 'true', 'yes', 'on']);
const enabled = truthy.has(String(process.env.HERMES_ENABLE_EXPERIMENTAL_WHATSAPP_BRIDGE || '').toLowerCase());

if (!enabled) {
  console.error([
    'Hermes WhatsApp bridge is disabled by default in hermes-agent-iot.',
    '',
    'Reason: the optional Baileys dependency currently has a critical advisory',
    'with no fixed version available (GHSA-qvv5-jq5g-4cgg).',
    '',
    'If you accept this risk, run the bridge only on an isolated/full-profile host:',
    '  cd scripts/whatsapp-bridge',
    '  npm run install:unsafe-baileys',
    '  HERMES_ENABLE_EXPERIMENTAL_WHATSAPP_BRIDGE=1 npm start',
  ].join('\n'));
  process.exit(78);
}

try {
  await import('./bridge-unsafe-baileys.js');
} catch (error) {
  if (error && error.code === 'ERR_MODULE_NOT_FOUND' && String(error.message || '').includes('@whiskeysockets/baileys')) {
    console.error('Baileys is not installed. Run `npm run install:unsafe-baileys` after reviewing GHSA-qvv5-jq5g-4cgg.');
    process.exit(78);
  }
  throw error;
}
