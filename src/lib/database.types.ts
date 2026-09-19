export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      addresses: {
        Row: {
          address_line: string
          created_at: string
          customer_id: string
          id: string
          instructions: string | null
          is_default: boolean
          label: string
          landmark: string | null
          latitude: number | null
          longitude: number | null
          postal_code: string | null
          province: string | null
          suburb_village: string | null
          town: string | null
        }
        Insert: {
          address_line: string
          created_at?: string
          customer_id: string
          id?: string
          instructions?: string | null
          is_default?: boolean
          label?: string
          landmark?: string | null
          latitude?: number | null
          longitude?: number | null
          postal_code?: string | null
          province?: string | null
          suburb_village?: string | null
          town?: string | null
        }
        Update: {
          address_line?: string
          created_at?: string
          customer_id?: string
          id?: string
          instructions?: string | null
          is_default?: boolean
          label?: string
          landmark?: string | null
          latitude?: number | null
          longitude?: number | null
          postal_code?: string | null
          province?: string | null
          suburb_village?: string | null
          town?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "addresses_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: number
          metadata: Json
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: never
          metadata?: Json
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: never
          metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      cart_items: {
        Row: {
          cart_id: string
          created_at: string
          id: string
          option_price_delta: number
          product_id: string
          quantity: number
          selected_options: Json
          variant_key: string
        }
        Insert: {
          cart_id: string
          created_at?: string
          id?: string
          option_price_delta?: number
          product_id: string
          quantity: number
          selected_options?: Json
          variant_key?: string
        }
        Update: {
          cart_id?: string
          created_at?: string
          id?: string
          option_price_delta?: number
          product_id?: string
          quantity?: number
          selected_options?: Json
          variant_key?: string
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "carts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      carts: {
        Row: {
          created_at: string
          customer_id: string
          id: string
          merchant_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          customer_id: string
          id?: string
          merchant_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          customer_id?: string
          id?: string
          merchant_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "carts_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "carts_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      deliveries: {
        Row: {
          created_at: string
          delivered_at: string | null
          driver_id: string | null
          id: string
          order_id: string
          pickup_at: string | null
          proof_url: string | null
        }
        Insert: {
          created_at?: string
          delivered_at?: string | null
          driver_id?: string | null
          id?: string
          order_id: string
          pickup_at?: string | null
          proof_url?: string | null
        }
        Update: {
          created_at?: string
          delivered_at?: string | null
          driver_id?: string | null
          id?: string
          order_id?: string
          pickup_at?: string | null
          proof_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "deliveries_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "deliveries_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      delivery_events: {
        Row: {
          created_at: string
          delivery_id: string
          event_type: string
          id: number
          latitude: number | null
          longitude: number | null
          metadata: Json
        }
        Insert: {
          created_at?: string
          delivery_id: string
          event_type: string
          id?: never
          latitude?: number | null
          longitude?: number | null
          metadata?: Json
        }
        Update: {
          created_at?: string
          delivery_id?: string
          event_type?: string
          id?: never
          latitude?: number | null
          longitude?: number | null
          metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "delivery_events_delivery_id_fkey"
            columns: ["delivery_id"]
            isOneToOne: false
            referencedRelation: "deliveries"
            referencedColumns: ["id"]
          },
        ]
      }
      delivery_zones: {
        Row: {
          base_fee: number
          id: string
          is_active: boolean
          max_distance_km: number | null
          name: string
          per_km_fee: number
          province: string | null
          town: string | null
        }
        Insert: {
          base_fee?: number
          id?: string
          is_active?: boolean
          max_distance_km?: number | null
          name: string
          per_km_fee?: number
          province?: string | null
          town?: string | null
        }
        Update: {
          base_fee?: number
          id?: string
          is_active?: boolean
          max_distance_km?: number | null
          name?: string
          per_km_fee?: number
          province?: string | null
          town?: string | null
        }
        Relationships: []
      }
      dispatch_offers: {
        Row: {
          driver_id: string
          expires_at: string | null
          id: string
          offered_at: string
          order_id: string
          responded_at: string | null
          status: string
        }
        Insert: {
          driver_id: string
          expires_at?: string | null
          id?: string
          offered_at?: string
          order_id: string
          responded_at?: string | null
          status?: string
        }
        Update: {
          driver_id?: string
          expires_at?: string | null
          id?: string
          offered_at?: string
          order_id?: string
          responded_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "dispatch_offers_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "dispatch_offers_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_locations: {
        Row: {
          accuracy_m: number | null
          driver_id: string
          heading: number | null
          latitude: number
          longitude: number
          updated_at: string
        }
        Insert: {
          accuracy_m?: number | null
          driver_id: string
          heading?: number | null
          latitude: number
          longitude: number
          updated_at?: string
        }
        Update: {
          accuracy_m?: number | null
          driver_id?: string
          heading?: number | null
          latitude?: number
          longitude?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_locations_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: true
            referencedRelation: "drivers"
            referencedColumns: ["user_id"]
          },
        ]
      }
      drivers: {
        Row: {
          approved: boolean
          created_at: string
          current_zone_id: string | null
          state: Database["public"]["Enums"]["driver_state"]
          user_id: string
          vehicle_registration: string | null
          vehicle_type: string | null
        }
        Insert: {
          approved?: boolean
          created_at?: string
          current_zone_id?: string | null
          state?: Database["public"]["Enums"]["driver_state"]
          user_id: string
          vehicle_registration?: string | null
          vehicle_type?: string | null
        }
        Update: {
          approved?: boolean
          created_at?: string
          current_zone_id?: string | null
          state?: Database["public"]["Enums"]["driver_state"]
          user_id?: string
          vehicle_registration?: string | null
          vehicle_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "drivers_current_zone_id_fkey"
            columns: ["current_zone_id"]
            isOneToOne: false
            referencedRelation: "delivery_zones"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "drivers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_branches: {
        Row: {
          address_line: string
          created_at: string
          id: string
          is_active: boolean
          is_open: boolean
          landmark: string | null
          latitude: number | null
          longitude: number | null
          merchant_id: string
          min_order: number
          name: string
          phone: string | null
          province: string | null
          suburb_village: string | null
          town: string | null
        }
        Insert: {
          address_line: string
          created_at?: string
          id?: string
          is_active?: boolean
          is_open?: boolean
          landmark?: string | null
          latitude?: number | null
          longitude?: number | null
          merchant_id: string
          min_order?: number
          name: string
          phone?: string | null
          province?: string | null
          suburb_village?: string | null
          town?: string | null
        }
        Update: {
          address_line?: string
          created_at?: string
          id?: string
          is_active?: boolean
          is_open?: boolean
          landmark?: string | null
          latitude?: number | null
          longitude?: number | null
          merchant_id?: string
          min_order?: number
          name?: string
          phone?: string | null
          province?: string | null
          suburb_village?: string | null
          town?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "merchant_branches_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_hours: {
        Row: {
          branch_id: string
          closes_at: string | null
          day_of_week: number
          id: string
          is_closed: boolean
          opens_at: string | null
        }
        Insert: {
          branch_id: string
          closes_at?: string | null
          day_of_week: number
          id?: string
          is_closed?: boolean
          opens_at?: string | null
        }
        Update: {
          branch_id?: string
          closes_at?: string | null
          day_of_week?: number
          id?: string
          is_closed?: boolean
          opens_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "merchant_hours_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "merchant_branches"
            referencedColumns: ["id"]
          },
        ]
      }
      merchant_staff: {
        Row: {
          created_at: string
          is_active: boolean
          merchant_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          is_active?: boolean
          merchant_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          is_active?: boolean
          merchant_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "merchant_staff_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "merchant_staff_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      merchants: {
        Row: {
          banner_url: string | null
          category: string | null
          commission_rate: number
          created_at: string
          description: string | null
          email: string | null
          id: string
          is_demo: boolean
          landmark: string | null
          logo_url: string | null
          merchant_mode: string | null
          name: string
          onboarding_completed_at: string | null
          ordering_features: Json
          owner_id: string | null
          owner_name: string | null
          payout_details: Json
          phone: string | null
          registration_number: string | null
          slug: string
          status: Database["public"]["Enums"]["merchant_status"]
          supports_delivery: boolean
          supports_pickup: boolean
          terms_accepted_at: string | null
          township_section: string | null
          updated_at: string
          whatsapp_number: string | null
        }
        Insert: {
          banner_url?: string | null
          category?: string | null
          commission_rate?: number
          created_at?: string
          description?: string | null
          email?: string | null
          id?: string
          is_demo?: boolean
          landmark?: string | null
          logo_url?: string | null
          merchant_mode?: string | null
          name: string
          onboarding_completed_at?: string | null
          ordering_features?: Json
          owner_id?: string | null
          owner_name?: string | null
          payout_details?: Json
          phone?: string | null
          registration_number?: string | null
          slug: string
          status?: Database["public"]["Enums"]["merchant_status"]
          supports_delivery?: boolean
          supports_pickup?: boolean
          terms_accepted_at?: string | null
          township_section?: string | null
          updated_at?: string
          whatsapp_number?: string | null
        }
        Update: {
          banner_url?: string | null
          category?: string | null
          commission_rate?: number
          created_at?: string
          description?: string | null
          email?: string | null
          id?: string
          is_demo?: boolean
          landmark?: string | null
          logo_url?: string | null
          merchant_mode?: string | null
          name?: string
          onboarding_completed_at?: string | null
          ordering_features?: Json
          owner_id?: string | null
          owner_name?: string | null
          payout_details?: Json
          phone?: string | null
          registration_number?: string | null
          slug?: string
          status?: Database["public"]["Enums"]["merchant_status"]
          supports_delivery?: boolean
          supports_pickup?: boolean
          terms_accepted_at?: string | null
          township_section?: string | null
          updated_at?: string
          whatsapp_number?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "merchants_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string
          channel: string
          created_at: string
          id: string
          read_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          channel?: string
          created_at?: string
          id?: string
          read_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          channel?: string
          created_at?: string
          id?: string
          read_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          id: string
          line_total: number
          options_snapshot: Json
          order_id: string
          product_id: string | null
          product_name: string
          quantity: number
          sku: string | null
          unit_price: number
        }
        Insert: {
          id?: string
          line_total: number
          options_snapshot?: Json
          order_id: string
          product_id?: string | null
          product_name: string
          quantity: number
          sku?: string | null
          unit_price: number
        }
        Update: {
          id?: string
          line_total?: number
          options_snapshot?: Json
          order_id?: string
          product_id?: string | null
          product_name?: string
          quantity?: number
          sku?: string | null
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      order_status_history: {
        Row: {
          actor_id: string | null
          created_at: string
          id: number
          new_status: Database["public"]["Enums"]["order_status"]
          note: string | null
          order_id: string
          previous_status: Database["public"]["Enums"]["order_status"] | null
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          id?: never
          new_status: Database["public"]["Enums"]["order_status"]
          note?: string | null
          order_id: string
          previous_status?: Database["public"]["Enums"]["order_status"] | null
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          id?: never
          new_status?: Database["public"]["Enums"]["order_status"]
          note?: string | null
          order_id?: string
          previous_status?: Database["public"]["Enums"]["order_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "order_status_history_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_status_history_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          branch_id: string
          created_at: string
          currency: string
          customer_id: string
          delivery_address_id: string | null
          delivery_address_snapshot: Json
          delivery_fee: number
          discount: number
          driver_id: string | null
          fulfillment_type: string
          id: string
          merchant_id: string
          notes: string | null
          order_number: number
          service_fee: number
          status: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total: number
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          currency?: string
          customer_id: string
          delivery_address_id?: string | null
          delivery_address_snapshot?: Json
          delivery_fee?: number
          discount?: number
          driver_id?: string | null
          fulfillment_type?: string
          id?: string
          merchant_id: string
          notes?: string | null
          order_number?: never
          service_fee?: number
          status?: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total: number
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          currency?: string
          customer_id?: string
          delivery_address_id?: string | null
          delivery_address_snapshot?: Json
          delivery_fee?: number
          discount?: number
          driver_id?: string | null
          fulfillment_type?: string
          id?: string
          merchant_id?: string
          notes?: string | null
          order_number?: never
          service_fee?: number
          status?: Database["public"]["Enums"]["order_status"]
          subtotal?: number
          total?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "merchant_branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_delivery_address_id_fkey"
            columns: ["delivery_address_id"]
            isOneToOne: false
            referencedRelation: "addresses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "orders_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_events: {
        Row: {
          created_at: string
          event_type: string
          id: number
          payload: Json
          payment_id: string | null
          provider_event_id: string | null
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: never
          payload?: Json
          payment_id?: string | null
          provider_event_id?: string | null
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: never
          payload?: Json
          payment_id?: string | null
          provider_event_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_events_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          idempotency_key: string | null
          metadata: Json
          order_id: string
          provider: string
          provider_reference: string | null
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          idempotency_key?: string | null
          metadata?: Json
          order_id: string
          provider: string
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          idempotency_key?: string | null
          metadata?: Json
          order_id?: string
          provider?: string
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_settings: {
        Row: {
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      product_categories: {
        Row: {
          id: string
          is_active: boolean
          merchant_id: string
          name: string
          sort_order: number
        }
        Insert: {
          id?: string
          is_active?: boolean
          merchant_id: string
          name: string
          sort_order?: number
        }
        Update: {
          id?: string
          is_active?: boolean
          merchant_id?: string
          name?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "product_categories_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      product_options: {
        Row: {
          id: string
          is_active: boolean
          name: string
          price_delta: number
          product_id: string
        }
        Insert: {
          id?: string
          is_active?: boolean
          name: string
          price_delta?: number
          product_id: string
        }
        Update: {
          id?: string
          is_active?: boolean
          name?: string
          price_delta?: number
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_options_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          category_id: string | null
          created_at: string
          description: string | null
          extras: Json
          id: string
          image_url: string | null
          is_active: boolean
          is_special: boolean
          merchant_id: string
          name: string
          pack_sizes: Json
          preparation_options: Json
          price: number
          sku: string | null
          special_label: string | null
          stock_quantity: number | null
          track_stock: boolean
          unit_label: string | null
          updated_at: string
        }
        Insert: {
          category_id?: string | null
          created_at?: string
          description?: string | null
          extras?: Json
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_special?: boolean
          merchant_id: string
          name: string
          pack_sizes?: Json
          preparation_options?: Json
          price: number
          sku?: string | null
          special_label?: string | null
          stock_quantity?: number | null
          track_stock?: boolean
          unit_label?: string | null
          updated_at?: string
        }
        Update: {
          category_id?: string | null
          created_at?: string
          description?: string | null
          extras?: Json
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_special?: boolean
          merchant_id?: string
          name?: string
          pack_sizes?: Json
          preparation_options?: Json
          price?: number
          sku?: string | null
          special_label?: string | null
          stock_quantity?: number | null
          track_stock?: boolean
          unit_label?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "product_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          first_name: string | null
          id: string
          last_name: string | null
          phone: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          first_name?: string | null
          id: string
          last_name?: string | null
          phone?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          first_name?: string | null
          id?: string
          last_name?: string | null
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      promotion_redemptions: {
        Row: {
          created_at: string
          customer_id: string
          id: string
          order_id: string
          promotion_id: string
        }
        Insert: {
          created_at?: string
          customer_id: string
          id?: string
          order_id: string
          promotion_id: string
        }
        Update: {
          created_at?: string
          customer_id?: string
          id?: string
          order_id?: string
          promotion_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "promotion_redemptions_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promotion_redemptions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promotion_redemptions_promotion_id_fkey"
            columns: ["promotion_id"]
            isOneToOne: false
            referencedRelation: "promotions"
            referencedColumns: ["id"]
          },
        ]
      }
      promotions: {
        Row: {
          code: string
          discount_type: string
          ends_at: string | null
          id: string
          is_active: boolean
          merchant_id: string | null
          starts_at: string | null
          usage_limit: number | null
          value: number
        }
        Insert: {
          code: string
          discount_type: string
          ends_at?: string | null
          id?: string
          is_active?: boolean
          merchant_id?: string | null
          starts_at?: string | null
          usage_limit?: number | null
          value?: number
        }
        Update: {
          code?: string
          discount_type?: string
          ends_at?: string | null
          id?: string
          is_active?: boolean
          merchant_id?: string | null
          starts_at?: string | null
          usage_limit?: number | null
          value?: number
        }
        Relationships: [
          {
            foreignKeyName: "promotions_merchant_id_fkey"
            columns: ["merchant_id"]
            isOneToOne: false
            referencedRelation: "merchants"
            referencedColumns: ["id"]
          },
        ]
      }
      refunds: {
        Row: {
          amount: number
          created_at: string
          id: string
          payment_id: string
          provider_reference: string | null
          reason: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          payment_id: string
          provider_reference?: string | null
          reason?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          payment_id?: string
          provider_reference?: string | null
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "refunds_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_set_driver_approval: {
        Args: { p_approved: boolean; p_driver_id: string }
        Returns: undefined
      }
      admin_set_merchant_status: {
        Args: {
          p_merchant_id: string
          p_status: Database["public"]["Enums"]["merchant_status"]
        }
        Returns: undefined
      }
      advance_delivery: {
        Args: {
          p_order_id: string
          p_status: Database["public"]["Enums"]["order_status"]
        }
        Returns: Database["public"]["Enums"]["order_status"]
      }
      apply_payment_event: {
        Args: {
          p_event_id: string
          p_event_type: string
          p_payload?: Json
          p_payment_id: string
          p_provider_reference: string
          p_status: Database["public"]["Enums"]["payment_status"]
        }
        Returns: Json
      }
      can_manage_merchant: { Args: { mid: string }; Returns: boolean }
      checkout_cart: {
        Args: { p_address_id: string; p_branch_id: string; p_notes?: string }
        Returns: string
      }
      checkout_cart_v2: {
        Args: {
          p_address_id?: string
          p_branch_id: string
          p_fulfillment: string
          p_notes?: string
        }
        Returns: string
      }
      has_role: {
        Args: { r: Database["public"]["Enums"]["app_role"] }
        Returns: boolean
      }
      is_admin: { Args: never; Returns: boolean }
      merchant_advance_order: {
        Args: {
          p_order_id: string
          p_status: Database["public"]["Enums"]["order_status"]
        }
        Returns: undefined
      }
      merchant_complete_pickup: {
        Args: { p_order_id: string }
        Returns: undefined
      }
      prepare_payment_session: {
        Args: { p_order_id: string; p_provider: string }
        Returns: Json
      }
      prepare_yoco_payment: { Args: { p_order_id: string }; Returns: Json }
      quote_delivery_fee: {
        Args: { p_address_id: string; p_branch_id: string }
        Returns: Json
      }
      respond_dispatch_offer: {
        Args: { p_accept: boolean; p_offer_id: string }
        Returns: string
      }
      set_driver_availability: {
        Args: { p_available: boolean }
        Returns: Database["public"]["Enums"]["driver_state"]
      }
    }
    Enums: {
      app_role:
        | "customer"
        | "merchant_owner"
        | "merchant_staff"
        | "driver"
        | "admin"
        | "super_admin"
      driver_state:
        | "offline"
        | "available"
        | "offered_job"
        | "assigned"
        | "at_pickup"
        | "delivering"
      merchant_status:
        | "draft"
        | "submitted"
        | "under_review"
        | "approved"
        | "rejected"
        | "suspended"
      order_status:
        | "pending_payment"
        | "paid"
        | "merchant_confirmed"
        | "preparing"
        | "ready_for_pickup"
        | "driver_assigned"
        | "picked_up"
        | "out_for_delivery"
        | "delivered"
        | "cancelled"
        | "refunded"
      payment_status:
        | "pending"
        | "processing"
        | "paid"
        | "failed"
        | "cancelled"
        | "refunded"
        | "partially_refunded"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: [
        "customer",
        "merchant_owner",
        "merchant_staff",
        "driver",
        "admin",
        "super_admin",
      ],
      driver_state: [
        "offline",
        "available",
        "offered_job",
        "assigned",
        "at_pickup",
        "delivering",
      ],
      merchant_status: [
        "draft",
        "submitted",
        "under_review",
        "approved",
        "rejected",
        "suspended",
      ],
      order_status: [
        "pending_payment",
        "paid",
        "merchant_confirmed",
        "preparing",
        "ready_for_pickup",
        "driver_assigned",
        "picked_up",
        "out_for_delivery",
        "delivered",
        "cancelled",
        "refunded",
      ],
      payment_status: [
        "pending",
        "processing",
        "paid",
        "failed",
        "cancelled",
        "refunded",
        "partially_refunded",
      ],
    },
  },
} as const
