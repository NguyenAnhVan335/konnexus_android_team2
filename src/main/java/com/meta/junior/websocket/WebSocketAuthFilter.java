package alan.nguyen.websocket;

import io.quarkus.vertx.web.RouteFilter;
import io.vertx.ext.web.RoutingContext;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class WebSocketAuthFilter {

    //set the priority up to 10000 in order to activate this function first when running project
    @RouteFilter(10000)
    public void addTokenToHeader(RoutingContext rc){
        //get token from url (?token=....)
        String token = rc.request().getParam("token");
        //check if this request is for chatting and has token.
        if(token!=null && rc.request().path().startsWith("/chat/")){
            // add header
            rc.request().headers().add("Authorization", "Bearer "+token);
        }
        //allow request to continue
        rc.next();
    }
}
