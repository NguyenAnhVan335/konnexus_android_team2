package alan.nguyen.controller;

import alan.nguyen.service.CloudinaryService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.resteasy.reactive.RestForm;
import org.jboss.resteasy.reactive.multipart.FileUpload;

import javax.print.attribute.standard.Media;
import java.awt.*;
import java.io.File;
import java.io.IOException;

@Path("/api/upload")
@Authenticated
public class FileUploadController {

    @Inject
    CloudinaryService cloudinaryService;

    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response uploadFile(@RestForm("file")FileUpload fileUpload){
        try {
            //get the temporary file when getting request
            File file = fileUpload.filePath().toFile();

            //Push to Cloudinary and get the link
            String file_url = cloudinaryService.uploadFile(file);

            return Response.ok("{\"url\":\"" + file_url + "\"}").build();
        }catch (IOException e){
            e.printStackTrace();
            return Response.serverError().entity("{\"error\":\"Upload file thất bại\"}").build();
        }
    }

}
