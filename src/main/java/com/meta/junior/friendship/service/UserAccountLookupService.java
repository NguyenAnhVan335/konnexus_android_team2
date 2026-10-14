// package com.meta.junior.friendship.service;

// import com.meta.junior.friendship.exception.ApiException;
// import jakarta.enterprise.context.ApplicationScoped;
// import jakarta.inject.Inject;
// import org.eclipse.microprofile.config.inject.ConfigProperty;

// import javax.sql.DataSource;
// import java.sql.Connection;
// import java.sql.PreparedStatement;
// import java.sql.ResultSet;
// import java.sql.SQLException;
// import java.util.UUID;

// /**
// * This project snapshot does not include the user's account
// entity/repository.
// * The SQL is configurable so it can be matched to the actual user table.
// */
// @ApplicationScoped
// public class UserAccountLookupService {

// @Inject
// DataSource dataSource;

// @ConfigProperty(name = "konnexus.user-exists-sql")
// String userExistsSql;

// public boolean exists(UUID userId) {
// try (Connection connection = dataSource.getConnection();
// PreparedStatement statement = connection.prepareStatement(userExistsSql)) {
// statement.setObject(1, userId);
// try (ResultSet resultSet = statement.executeQuery()) {
// return resultSet.next() && resultSet.getBoolean(1);
// }
// } catch (SQLException exception) {
// throw new ApiException(
// 503,
// "Không thể kiểm tra tài khoản người dùng. Hãy kiểm tra cấu hình câu lệnh
// USER_EXISTS_SQL.",
// exception
// );
// }
// }
// }
