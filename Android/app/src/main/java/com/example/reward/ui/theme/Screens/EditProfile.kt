package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.R
import com.example.reward.data.Composables.bottombaricon
import com.example.reward.data.Composables.textFieldFun
import com.example.reward.data.Composables.transparentText

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun editprofilescreen(){

    Scaffold (
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Profile Setting", fontWeight = FontWeight.Bold) })
        },
        bottomBar = {
            bottombaricon()
        }
    ){
        paddingValues ->

        Column (modifier = Modifier.padding(paddingValues)){

            Image(modifier = Modifier.offset(150.dp)
                .size(90.dp),
                painter = painterResource(R.drawable.profilepic), contentDescription = "profile Pic")
            Spacer(modifier = Modifier.height(20.dp))
            Text(modifier = Modifier.offset(110.dp),
                text = "Change profile picture", fontWeight = FontWeight.Bold, fontSize = 19.sp)
            Spacer(modifier = Modifier.height(30.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ){

                    TextField(
                        value = "First Name", // اربطها بـ State
                        onValueChange = {},
                        placeholder = { Text("") },
                        modifier = Modifier.height(70.dp)
                            .weight(1f),
                        shape = RoundedCornerShape(20.dp), colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White
                        )
                    )

                    TextField(
                        value = "Last Name ",
                        onValueChange = { it },
                        modifier = Modifier.height(70.dp)
                            .weight(1f),
                        shape = RoundedCornerShape(20.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White
                        )
                    )
                }




            Spacer(modifier = Modifier.height(20.dp))
            transparentText("Email")

            Spacer(modifier = Modifier.height(20.dp))
            transparentText("Phone Number")

            Spacer(modifier = Modifier.height(20.dp))
            transparentText("Full Address")
            Spacer(modifier = Modifier.height(20.dp))
            transparentText("Password")
            Spacer(modifier = Modifier.height(20.dp))
                        Button(
                        onClick = { },
                modifier = Modifier.offset(60.dp)
                    .width(300.dp)
                    .height(60.dp),
                shape = RoundedCornerShape(100.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF134F49))
            ) {
                Text(
                    "Save", fontSize = 18.sp, color = Color.White,)
            }

        }
    }
}