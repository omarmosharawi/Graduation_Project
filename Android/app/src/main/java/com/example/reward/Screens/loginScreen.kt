import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.R

class LoginHeaderShape : Shape {
    override fun createOutline(
        size: androidx.compose.ui.geometry.Size,
        layoutDirection: LayoutDirection,
        density: Density
    ): Outline {
        val path = Path().apply {
            moveTo(0f, 0f)
            lineTo(size.width, 0f)
            lineTo(size.width, size.height * 0.4f) // نزول من اليمين
            lineTo(size.width * 0.35f, size.height) // النقطة المنحدرة
            lineTo(0f, size.height * 0.7f) // الرجوع للشمال
            close()
        }
        return Outline.Generic(path)
    }
}

@Composable
fun LoginScreen() {

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .verticalScroll(rememberScrollState()), // عشان لو الشاشة صغيرة تقدر تعمل سكرول
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 1. الجزء العلوي (Header)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(320.dp)
                .graphicsLayer {
                    shape = LoginHeaderShape()
                    clip = true
                }
                .background(Color(0xFF134F49)),
            contentAlignment = Alignment.Center
        ) {
            Image(
                painter = painterResource(id = R.drawable.reward), // اسم الصورة عندك
                contentDescription = "Logo",
                modifier = Modifier.size(250.dp)
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 2. محتوى الفورم
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 25.dp)
        ) {
            Text(
                text = "Login to your account",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF134F49)
            )

            Spacer(modifier = Modifier.height(25.dp))

            // حقل الإيميل
            TextField(
                value = "", // اربطها بـ State
                onValueChange = {},
                placeholder = { Text("Enter your email") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(15.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color(0xFFE2F3E1),
                    unfocusedContainerColor = Color(0xFFE2F3E1),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                )
            )

            Spacer(modifier = Modifier.height(20.dp))

            // حقل الباسورد
            TextField(
                value = "",
                onValueChange = {},
                placeholder = { Text("Enter password") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(15.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color(0xFFE2F3E1),
                    unfocusedContainerColor = Color(0xFFE2F3E1),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                )
            )

            Spacer(modifier = Modifier.height(15.dp))

            // Remember Me & Forgot Password
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = true, onCheckedChange = {})
                    Text("Remember Me", fontSize = 14.sp)
                }
                Text("Forgotten password?", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(30.dp))

            // زرار الـ Login
            Button(
                onClick = { },
                modifier = Modifier.fillMaxWidth().height(55.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF134F49))
            ) {
                Text("Login", fontSize = 18.sp, color = Color.White)
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Or Divider
            Row(verticalAlignment = Alignment.CenterVertically) {
                HorizontalDivider(modifier = Modifier.weight(1f))
                Text(" Or ", modifier = Modifier.padding(horizontal = 10.dp))
                HorizontalDivider(modifier = Modifier.weight(1f))
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Google Login (تحتاج أيقونة جوجل في الـ drawable)
            OutlinedButton(
                onClick = {},
                modifier = Modifier.fillMaxWidth().height(55.dp),
                shape = RoundedCornerShape(25.dp),
                border = BorderStroke(0.dp, Color.Transparent)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    // Image(painter = painterResource(id = R.drawable.ic_google), ...)
                    Text("Continue with Google", color = Color.Black)
                }
            }

            // Sign Up Text
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                Text("Don't have an account? ")
                Text("Sign Up", color = Color(0xFF134F49), fontWeight = FontWeight.Bold)
            }
        }
    }
}