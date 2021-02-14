export default {
  resource: 'admin.adminPlugins',
  path: '/plugins',
  map() {
    this.route('auth0-extension');
  }
};