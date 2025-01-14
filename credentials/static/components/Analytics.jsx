// TODO: We should be able to remove this as part of https://github.com/openedx/credentials/issues/1722
// Function that wraps analytics.track so that it can be also be called directly
function trackEvent(name, properties) {
  // Only load the key if it has been injected into the page already
  // This enables easy testing that doesn't create GA events
  if (window.analytics) {
    window.analytics.track(name, properties);
  }
}

export default trackEvent;
