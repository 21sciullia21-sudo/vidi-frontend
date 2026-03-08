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
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      assets: {
        Row: {
          category: string
          created_at: string | null
          description: string
          download_url: string | null
          downloads: number | null
          id: string
          image_url: string | null
          price: number
          seller_id: string | null
          title: string
        }
        Insert: {
          category: string
          created_at?: string | null
          description: string
          download_url?: string | null
          downloads?: number | null
          id?: string
          image_url?: string | null
          price: number
          seller_id?: string | null
          title: string
        }
        Update: {
          category?: string
          created_at?: string | null
          description?: string
          download_url?: string | null
          downloads?: number | null
          id?: string
          image_url?: string | null
          price?: number
          seller_id?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "assets_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      bids: {
        Row: {
          amount: number
          delivery_days: number
          editor_id: string | null
          id: string
          job_id: string | null
          proposal: string
          status: string | null
          submitted_at: string | null
        }
        Insert: {
          amount: number
          delivery_days: number
          editor_id?: string | null
          id?: string
          job_id?: string | null
          proposal: string
          status?: string | null
          submitted_at?: string | null
        }
        Update: {
          amount?: number
          delivery_days?: number
          editor_id?: string | null
          id?: string
          job_id?: string | null
          proposal?: string
          status?: string | null
          submitted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bids_editor_id_fkey"
            columns: ["editor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bids_job_id_fkey"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          content: string
          created_at: string | null
          id: string
          post_id: string | null
          user_id: string | null
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          post_id?: string | null
          user_id?: string | null
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          post_id?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          id: string
          last_message: string | null
          last_message_at: string
          participant_ids: string[]
          unread_count: Json | null
        }
        Insert: {
          created_at?: string
          id?: string
          last_message?: string | null
          last_message_at?: string
          participant_ids: string[]
          unread_count?: Json | null
        }
        Update: {
          created_at?: string
          id?: string
          last_message?: string | null
          last_message_at?: string
          participant_ids?: string[]
          unread_count?: Json | null
        }
        Relationships: []
      }
      jobs: {
        Row: {
          bid_count: number | null
          budget_max: number
          budget_min: number
          category: string
          client_id: string | null
          deadline: string
          description: string
          id: string
          posted_at: string | null
          reference_images: string[] | null
          requirements: string | null
          status: string | null
          title: string
        }
        Insert: {
          bid_count?: number | null
          budget_max: number
          budget_min: number
          category: string
          client_id?: string | null
          deadline: string
          description: string
          id?: string
          posted_at?: string | null
          reference_images?: string[] | null
          requirements?: string | null
          status?: string | null
          title: string
        }
        Update: {
          bid_count?: number | null
          budget_max?: number
          budget_min?: number
          category?: string
          client_id?: string | null
          deadline?: string
          description?: string
          id?: string
          posted_at?: string | null
          reference_images?: string[] | null
          requirements?: string | null
          status?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "jobs_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          content: string
          conversation_id: string
          id: string
          is_read: boolean
          sender_id: string
          sent_at: string
        }
        Insert: {
          content: string
          conversation_id: string
          id?: string
          is_read?: boolean
          sender_id: string
          sent_at?: string
        }
        Update: {
          content?: string
          conversation_id?: string
          id?: string
          is_read?: boolean
          sender_id?: string
          sent_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_methods: {
        Row: {
          brand: string
          created_at: string | null
          exp_month: number
          exp_year: number
          id: string
          is_default: boolean | null
          last4: string
          user_id: string | null
        }
        Insert: {
          brand: string
          created_at?: string | null
          exp_month: number
          exp_year: number
          id?: string
          is_default?: boolean | null
          last4: string
          user_id?: string | null
        }
        Update: {
          brand?: string
          created_at?: string | null
          exp_month?: number
          exp_year?: number
          id?: string
          is_default?: boolean | null
          last4?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_methods_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          camera_info: Json | null
          clip_length: number | null
          comment_count: number | null
          content: string
          created_at: string | null
          id: string
          image_urls: string[] | null
          is_color_graded: boolean | null
          likes: string[] | null
          user_id: string | null
          video_format: string | null
          video_urls: string[] | null
        }
        Insert: {
          camera_info?: Json | null
          clip_length?: number | null
          comment_count?: number | null
          content: string
          created_at?: string | null
          id?: string
          image_urls?: string[] | null
          is_color_graded?: boolean | null
          likes?: string[] | null
          user_id?: string | null
          video_format?: string | null
          video_urls?: string[] | null
        }
        Update: {
          camera_info?: Json | null
          clip_length?: number | null
          comment_count?: number | null
          content?: string
          created_at?: string | null
          id?: string
          image_urls?: string[] | null
          is_color_graded?: boolean | null
          likes?: string[] | null
          user_id?: string | null
          video_format?: string | null
          video_urls?: string[] | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      purchases: {
        Row: {
          amount: number
          asset_id: string | null
          id: string
          purchased_at: string | null
          status: string | null
          stripe_session_id: string | null
          user_id: string | null
        }
        Insert: {
          amount: number
          asset_id?: string | null
          id?: string
          purchased_at?: string | null
          status?: string | null
          stripe_session_id?: string | null
          user_id?: string | null
        }
        Update: {
          amount?: number
          asset_id?: string | null
          id?: string
          purchased_at?: string | null
          status?: string | null
          stripe_session_id?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "purchases_asset_id_fkey"
            columns: ["asset_id"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string | null
          editing_style: string | null
          email: string
          featured_reel_url: string | null
          followers: number | null
          following: number | null
          following_ids: string[] | null
          full_name: string | null
          gear_badges: string[] | null
          hourly_rate: number | null
          id: string
          instagram_url: string | null
          is_new: boolean | null
          linkedin_url: string | null
          location: string | null
          portfolio_file: string | null
          portfolio_url: string | null
          project_count: number | null
          skill_level: string | null
          specializations: string[] | null
          twitter_url: string | null
          updated_at: string | null
          user_role: string | null
          username: string
          website_url: string | null
          youtube_url: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          editing_style?: string | null
          email: string
          featured_reel_url?: string | null
          followers?: number | null
          following?: number | null
          following_ids?: string[] | null
          full_name?: string | null
          gear_badges?: string[] | null
          hourly_rate?: number | null
          id?: string
          instagram_url?: string | null
          is_new?: boolean | null
          linkedin_url?: string | null
          location?: string | null
          portfolio_file?: string | null
          portfolio_url?: string | null
          project_count?: number | null
          skill_level?: string | null
          specializations?: string[] | null
          twitter_url?: string | null
          updated_at?: string | null
          user_role?: string | null
          username: string
          website_url?: string | null
          youtube_url?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          editing_style?: string | null
          email?: string
          featured_reel_url?: string | null
          followers?: number | null
          following?: number | null
          following_ids?: string[] | null
          full_name?: string | null
          gear_badges?: string[] | null
          hourly_rate?: number | null
          id?: string
          instagram_url?: string | null
          is_new?: boolean | null
          linkedin_url?: string | null
          location?: string | null
          portfolio_file?: string | null
          portfolio_url?: string | null
          project_count?: number | null
          skill_level?: string | null
          specializations?: string[] | null
          twitter_url?: string | null
          updated_at?: string | null
          user_role?: string | null
          username?: string
          website_url?: string | null
          youtube_url?: string | null
        }
        Relationships: []
      }
      vidi: {
        Row: {
          created_at: string
          id: number
        }
        Insert: {
          created_at?: string
          id?: number
        }
        Update: {
          created_at?: string
          id?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
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
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
