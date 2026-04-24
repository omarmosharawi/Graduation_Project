package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.example.reward.R
import com.example.reward.data.Composables.bottombaricon
import com.example.reward.data.Composables.reHeaderLogo
import com.example.reward.ui.theme.DarkGreen
import com.example.reward.ui.theme.orange1

@Composable
fun qrscreen () {

    Scaffold(topBar = {
        reHeaderLogo()
    },
        bottomBar = {

        NavigationBar( containerColor = DarkGreen){
            NavigationBarItem(
                selected = false,
                onClick = {},
                icon = {
                    Surface(
                        modifier = Modifier.size(80.dp)
                            .shadow(
                            elevation = 20.dp,
                            shape = CircleShape,
                            ambientColor = orange1,
                            spotColor = orange1
                        ),

                        shape = CircleShape,
                        color = Color.White,
                        shadowElevation = 10.dp
                    ) {
                        Box(contentAlignment = Alignment.Center, ) {
                            Icon(
                                painter = painterResource(id = R.drawable.qr),
                                contentDescription = "QR Code",
                                modifier = Modifier.size(60.dp),
                                tint = Color.Black
                            )
                        }
                    }
                }

            )
        }
    }

    )

{paddingValues ->
        Column (modifier = Modifier.padding(paddingValues) ){
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(400.dp)
            ) {
            Image(
                painter = painterResource(id = R.drawable.qrcode), // 1. الـ Painter الأول
                contentDescription = "QR Code",               // 2. الوصف
                modifier = Modifier
                    .size(400.dp)                              // حدد الحجم
                    .background(Color.White, CircleShape)     // 3. الخلفية لازم تكون فاتحة وشكلها دائري لو عايزها زي الصورة
                    .padding(16.dp)                           // مسافة داخلية عشان الـ QR ميلزقش في الحواف
            )


                // ده اللي بيرسم الزوايا
                Canvas(modifier = Modifier.size(350.dp)) {

                    val strokeWidth = 6.dp.toPx()
                    val cornerLength = 40.dp.toPx()

                    val width = size.width
                    val height = size.height

                    // Top Left
                    drawLine(
                        color = Color.Black,
                        start = Offset(0f, 0f),
                        end = Offset(cornerLength, 0f),
                        strokeWidth = strokeWidth
                    )
                    drawLine(
                        color = Color.Black,
                        start = Offset(0f, 0f),
                        end = Offset(0f, cornerLength),
                        strokeWidth = strokeWidth
                    )

                    // Top Right
                    drawLine(
                        color = Color.Black,
                        start = Offset(width, 0f),
                        end = Offset(width - cornerLength, 0f),
                        strokeWidth = strokeWidth
                    )
                    drawLine(
                        color = Color.Black,
                        start = Offset(width, 0f),
                        end = Offset(width, cornerLength),
                        strokeWidth = strokeWidth
                    )

                    // Bottom Left
                    drawLine(
                        color = Color.Black,
                        start = Offset(0f, height),
                        end = Offset(cornerLength, height),
                        strokeWidth = strokeWidth
                    )
                    drawLine(
                        color = Color.Black,
                        start = Offset(0f, height),
                        end = Offset(0f, height - cornerLength),
                        strokeWidth = strokeWidth
                    )

                    // Bottom Right
                    drawLine(
                        color = Color.Black,
                        start = Offset(width, height),
                        end = Offset(width - cornerLength, height),
                        strokeWidth = strokeWidth
                    )
                    drawLine(
                        color = Color.Black,
                        start = Offset(width, height),
                        end = Offset(width, height - cornerLength),
                        strokeWidth = strokeWidth
                    )
                }
        }
    }
}}

