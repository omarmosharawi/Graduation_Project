package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Sort
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.data.Composables.reHeaderLogo

@Composable
fun newpasswordscreen(){



    Column (
        horizontalAlignment = Alignment.Start, verticalArrangement = Arrangement.Center){
        reHeaderLogo()
        Text( color = androidx.compose.ui.graphics.Color(0xFF134F49),
            text = "Create New Password", fontWeight = FontWeight.Bold, fontSize = 32.sp)
        Spacer(Modifier.padding(23.dp) )
        Text("password" ,fontWeight = FontWeight.Bold, fontSize = 17.sp)
       OutlinedTextField(value = ""
           , onValueChange = {}
                   ,leadingIcon = {
               Icon(modifier = Modifier.offset(350.dp),
                   imageVector = Icons.Default.VisibilityOff,
                   contentDescription = null
               )
           },
           placeholder = { Text("") },
           modifier = Modifier.fillMaxWidth(),
           shape = RoundedCornerShape(16.dp)
       , singleLine = true)
        Spacer(Modifier.padding(20.dp))
        Text(" Confirm password" , modifier = Modifier.padding(end = 300.dp),fontWeight = FontWeight.Bold, fontSize = 13.sp)
        OutlinedTextField(value = ""
           , onValueChange = {}
                   ,leadingIcon = {
               Icon(modifier = Modifier.offset(350.dp),
                   imageVector = Icons.Default.VisibilityOff,
                   contentDescription = null
               )
           },
           placeholder = { Text("") },
           modifier = Modifier.fillMaxWidth(),
           shape = RoundedCornerShape(16.dp)
       , singleLine = true)

        Spacer(Modifier.padding(20.dp))

        // 🔹 Button
        Button(
            onClick = { },
            modifier = Modifier.padding(20.dp)
                .fillMaxWidth()
                .height(55.dp),
            shape = RoundedCornerShape(30.dp)
            ,colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF134F49))
        ) {
            Text("Reset Password")
        }

    }
}