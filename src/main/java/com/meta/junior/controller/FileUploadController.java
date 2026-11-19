package com.meta.junior.controller;

import com.meta.junior.service.CloudinaryService;
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

import java.io.IOException;
import java.util.Map;

@Path("/api/upload")
@Authenticated
public class FileUploadController {

    @Inject
    CloudinaryService cloudinaryService;

    @POST
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response uploadFile(@RestForm("file") FileUpload fileUpload) {
        // Multipart có thể gửi thiếu part "file" hoặc part rỗng.
        if (fileUpload == null || fileUpload.filePath() == null || fileUpload.size() == 0) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("message", "Vui lòng chọn tệp tin cần tải lên."))
                    .build();
        }

        try {
            //get the temporary file when getting request
            String fileUrl = cloudinaryService.uploadFile(fileUpload.filePath().toFile());

            if (fileUrl == null || fileUrl.isBlank()) {
                return Response.status(Response.Status.BAD_GATEWAY)
                        .entity(Map.of("message", "Cloudinary không trả về đường dẫn tệp."))
                        .build();
            }

            // Trả object JSON thật (Map) — không tự nối chuỗi JSON, vì Jackson sẽ
            // bọc chuỗi đó thành một JSON string khiến client không đọc được `url`.
            return Response.ok(Map.of("url", fileUrl)).build();
        } catch (IOException e) {
            e.printStackTrace();
            return Response.status(Response.Status.BAD_GATEWAY)
                    .entity(Map.of(
                            "message",
                            "Không thể tải tệp lên Cloudinary. Kiểm tra cấu hình CLOUDINARY_URL."
                    ))
                    .build();
        } catch (RuntimeException e) {
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(Map.of("message", "Tải tệp lên thất bại. Vui lòng thử lại."))
                    .build();
        }
    }

}
