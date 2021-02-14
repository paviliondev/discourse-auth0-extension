import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";

const Auth0Log = EmberObject.extend();

Auth0Log.reopenClass({
  list(params = {}) {
    return ajax('/admin/plugins/auth0-extension', {
      data: params
    }).catch(popupAjaxError);
  }
});

export default Auth0Log;

