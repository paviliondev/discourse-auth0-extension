import Auth0Log from '../models/oauth2-log';
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return Auth0Log.list();
  },
  
  setupController(controller, model) {
    controller.set('logs', model);
  }
})