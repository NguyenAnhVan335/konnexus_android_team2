package com.meta.junior.dto;


import com.meta.junior.common.SystemRole;
import lombok.Data;

@Data
public class UserDTO {
    public String username;
    public String email;
    public String password;
    public SystemRole role;
}
