package alan.nguyen.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.io.File;
import java.io.IOException;
import java.util.Map;

@ApplicationScoped
public class CloudinaryService {

    private Cloudinary cloudinary;
    public CloudinaryService(@ConfigProperty(name = "app.cloudinary.url") String cloudinary_url){
        this.cloudinary = new Cloudinary(cloudinary_url);
    }

    public String uploadFile(File file) throws IOException {
        Map uploadResult = cloudinary.uploader().upload(file, ObjectUtils.emptyMap());

        //return image's link
        return uploadResult.get("secure_url").toString();
    }
}
