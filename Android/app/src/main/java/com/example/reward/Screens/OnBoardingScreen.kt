package com.example.reward.Screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.ModifierLocalBeyondBoundsLayout
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.R

@Composable
fun OnBoardingscreen() {
    Column(
        modifier = Modifier
            .background(
                color = Color(
                    0xff134F49
                )
            )
            .fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {

        Image(
            painter = painterResource(id = R.drawable.reward),
            "logo",
            modifier = Modifier
                .size(300.dp)
                .padding(top = 30.dp)
        )

        // Spacer(modifier = Modifier.padding(0.dp))
        Image(
            painter = painterResource(id = R.drawable.bin),
            "bin",
            modifier = Modifier
                .size(300.dp)
        )

        Spacer(modifier = Modifier.padding(15.dp))

        Text(
            "Welcome to REward",
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 23.sp
        )
        Spacer(modifier = Modifier.padding(5.dp))

        Text("Earn rewards for recycling", color = Color.White, fontSize = 15.sp)

       //  Spacer(modifier = Modifier.padding(5.dp))

        Button(onClick = {},  modifier = Modifier.fillMaxSize().padding(horizontal = 50.dp, vertical = 90.dp)
            ,colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFFE2F3E1),
                contentColor= Color(0xFF407F79)
            )
        ) {
            Text(
                "Get Started", modifier = Modifier,
                fontSize = 18.sp

            )
        }
    }


}