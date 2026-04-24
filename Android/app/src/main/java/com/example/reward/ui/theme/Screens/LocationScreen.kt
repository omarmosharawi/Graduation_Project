package com.example.reward.ui.theme.Screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Sd
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ModifierLocalBeyondBoundsLayout
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.reward.data.Composables.LocationInputs
import com.example.reward.data.Composables.TransportModes
import com.example.reward.data.Composables.bottombaricon

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun locationscreen() {
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Location", fontWeight = FontWeight.Bold) }
            )
        }
       , bottomBar = { bottombaricon() }
    ){paddingValues ->
        Column(modifier = Modifier.padding(paddingValues)) {
            LocationInputs()
            Spacer(modifier = Modifier.padding(15.dp))
            TransportModes()

            RecentHistoryList()
            Spacer(modifier = Modifier.padding(30.dp))
            Text( modifier = Modifier.offset(80.dp),
                text = "More from recent history",
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp,
                color = Color(0xff134F49)
            )
            }


        }
        }

@Composable
fun RecentHistoryList() {
    val items = listOf(
        "Schön Dental Clinic", "Estia Dental", "North Plus Mall",
        "Canadian International college", "Downtown Katameya",
        "Ramses", "Down Town Mall"
    )

    LazyColumn(modifier = Modifier.padding(horizontal = 16.dp)) {
        items(items) { item ->
            Card(

                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(
                        containerColor = Color.Transparent
                        ),
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(12.dp)
                ) {
                    Icon(Icons.Default.AccessTime, contentDescription = null)
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(item)
                }
            }}}
        }

