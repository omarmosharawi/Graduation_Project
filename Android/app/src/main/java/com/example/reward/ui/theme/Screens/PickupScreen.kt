package com.example.reward.ui.theme.Screens

import android.provider.CalendarContract
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.data.Composables.DateItem
import com.example.reward.data.Composables.bottombaricon
import com.example.reward.data.Composables.homeHeader
import com.example.reward.data.Composables.reHeader
import com.example.reward.data.Composables.reHeaderLogo
import com.example.reward.data.Composables.textFieldFun

@Composable
fun pickupscreen() {

    Scaffold(
        topBar = { reHeaderLogo() },
        bottomBar = {
            bottombaricon()
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier.padding(horizontal = 20.dp)
                .padding(paddingValues)
        ) {
            stickyHeader {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(vertical = 12.dp)
                ) {
                    Text( modifier = Modifier.offset(59.dp),
                        text = "Schedule your Pick up",
                        fontWeight = FontWeight.Bold,
                        fontSize = 22.sp,
                        color = Color(0xff134F49)
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(10.dp)) }
            item { textFieldFun("Email ") }
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item { textFieldFun("Name ") }
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item { textFieldFun("Address ") }
            item { Spacer(modifier = Modifier.height(10.dp)) }

            item { textFieldFun("Location URL   (Google Maps) ") }
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item { textFieldFun("Phone ") }
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item { DateItem() }
            item { Spacer(modifier = Modifier.height(10.dp)) }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {

                    TextField(
                        value = "Material Type", // اربطها بـ State
                        onValueChange = {},
                        modifier = Modifier.height(60.dp)
                            .weight(1f),
                        shape = RoundedCornerShape(20.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color(0xFFE2F3E1),
                            unfocusedContainerColor = Color(0xFFE2F3E1)
                        )
                    )


                    TextField(
                        value = "Quantity",
                        onValueChange = { },
                        modifier = Modifier.height(60.dp)
                            .weight(1f),
                        shape = RoundedCornerShape(20.dp),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color(0xFFE2F3E1),
                            unfocusedContainerColor = Color(0xFFE2F3E1)
                        )


                    )

                }
}
                // ✅ زرار Add Material لوحده
                item {
                    Button(
                        onClick = { },
                        modifier = Modifier.padding(40.dp)
                            .fillMaxWidth()
                            .height(50.dp),
                        shape = RoundedCornerShape(25.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF134F49)
                        )
                    ) {
                        Text("Add Material", fontSize = 16.sp, color = Color.White)
                    }
                }
            item {
                Button(
                    onClick = { },
                    modifier = Modifier.fillMaxWidth()
                        .height(55.dp),
                    shape = RoundedCornerShape(25.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF134F49)
                    )
                ) {
                    Text("Confirm", fontSize = 18.sp, color = Color.White)
                }
            }
        }

        }

            }




